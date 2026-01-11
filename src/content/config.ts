import { defineCollection, z } from "astro:content";

const pages = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    slug: z.string().optional(),
    description: z.string().optional(),
    nav: z.boolean().default(false),
  }),
});

const paintings = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    slug: z.string().optional(),
    price: z.string().optional(),
    currency: z.string().optional(),
    images: z
      .array(
        z.object({
          src: z.string().url(),
          alt: z.string().optional().default(""),
        })
      )
      .default([]),
    categories: z
      .array(
        z.object({
          name: z.string(),
          slug: z.string(),
        })
      )
      .default([]),
    tags: z
      .array(
        z.object({
          name: z.string(),
          slug: z.string(),
        })
      )
      .default([]),
    isSold: z.boolean().default(false),
    availability: z.string().optional(),
  }),
});

export const collections = { pages, paintings };
