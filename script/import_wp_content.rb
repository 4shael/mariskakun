#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "net/http"
require "json"
require "uri"

BASE_URL = (ENV["WP_BASE_URL"] || "https://mariskakun.com").sub(%r{\/\z}, "")
ROOT_DIR = File.expand_path("..", __dir__)
PAGES_DIR = File.join(ROOT_DIR, "src", "content", "pages")
PAINTINGS_DIR = File.join(ROOT_DIR, "src", "content", "paintings")

IGNORED_PAGE_SLUGS = %w[
  donor-dashboard
  donation-confirmation
  donation-failed
  default-shop
  products
  cart
  checkout
].freeze

NAV_PAGE_SLUGS = %w[
  about-me
  contacts
  for-a-present
  terms-and-conditions
].freeze

def fetch_paginated_json(base_url, path, per_page: 100)
  items = []
  page = 1

  loop do
    uri = URI.join(base_url, path)
    uri.query = URI.encode_www_form(per_page: per_page, page: page)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      warn "Failed to fetch #{uri} (#{response.code})"
      break
    end

    page_items = JSON.parse(response.body)
    break if page_items.empty?

    items.concat(page_items)
    total_pages = response["X-WP-TotalPages"]&.to_i
    break if total_pages && page >= total_pages

    page += 1
    sleep 0.2
  end

  items
end

def strip_html(html)
  html.to_s.gsub(/<[^>]*>/, " ").gsub(/\s+/, " ").strip
end

def yaml_escape(value)
  value.to_s.gsub("\"", "\\\"")
end

def write_markdown(path, frontmatter, body)
  File.open(path, "w") do |file|
    file.puts "---"
    frontmatter.each do |key, value|
      next if value.nil?
      next if value.is_a?(String) && value.strip.empty?
      next if value.is_a?(Array) && value.empty?
      case value
      when TrueClass, FalseClass
        file.puts "#{key}: #{value}"
      when Array
        file.puts "#{key}:"
        value.each do |item|
          if item.is_a?(Hash)
            file.puts "  -"
            item.each do |sub_key, sub_value|
              file.puts "    #{sub_key}: \"#{yaml_escape(sub_value)}\""
            end
          else
            file.puts "  - \"#{yaml_escape(item)}\""
          end
        end
      else
        file.puts "#{key}: \"#{yaml_escape(value)}\""
      end
    end
    file.puts "---"
    file.puts
    file.puts body.to_s.strip
    file.puts
  end
end

FileUtils.mkdir_p(PAGES_DIR)
FileUtils.mkdir_p(PAINTINGS_DIR)

pages = fetch_paginated_json(BASE_URL, "/wp-json/wp/v2/pages")
products = fetch_paginated_json(BASE_URL, "/wp-json/wc/store/v1/products")

pages.each do |page|
  slug = page["slug"].to_s
  next if IGNORED_PAGE_SLUGS.include?(slug)

  title = page.dig("title", "rendered")
  description = strip_html(page.dig("excerpt", "rendered"))
  description = description[0, 160] if description.length > 160
  body = page.dig("content", "rendered") || ""

  frontmatter = {
    "title" => title,
    "slug" => slug,
    "description" => description,
    "nav" => NAV_PAGE_SLUGS.include?(slug),
  }

  write_markdown(File.join(PAGES_DIR, "#{slug}.md"), frontmatter, body)
end

products.each do |product|
  slug = product["slug"].to_s
  title = product["name"].to_s
  body = product["description"].to_s
  price = product.dig("prices", "price")
  currency = product.dig("prices", "currency_symbol")
  availability = product.dig("stock_availability", "class")

  is_sold = title.upcase.include?("SOLD") || body.downcase.include?("sold")

  images = product.fetch("images", []).map do |image|
    {
      "src" => image["src"],
      "alt" => image["alt"].to_s,
    }
  end

  categories = product.fetch("categories", []).map do |category|
    {
      "name" => category["name"],
      "slug" => category["slug"],
    }
  end

  tags = product.fetch("tags", []).map do |tag|
    {
      "name" => tag["name"],
      "slug" => tag["slug"],
    }
  end

  frontmatter = {
    "title" => title,
    "slug" => slug,
    "price" => price,
    "currency" => currency,
    "images" => images,
    "categories" => categories,
    "tags" => tags,
    "isSold" => is_sold,
    "availability" => availability,
  }

  write_markdown(File.join(PAINTINGS_DIR, "#{slug}.md"), frontmatter, body)
end

puts "Imported #{pages.size} pages and #{products.size} paintings."
