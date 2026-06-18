import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const posts = defineCollection({
  loader: glob({ base: './src/content/posts', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    category: z.enum(['dev', 'photo', 'music', 'writing', 'essay']),
    tags: z.array(z.string()).optional(),
    draft: z.boolean().optional().default(false),
  }),
});

const sharedFields = {
  title: z.string(),
  date: z.coerce.date(),
  category: z.string(),
  tags: z.array(z.string()).default([]),
  description: z.string(),
  draft: z.boolean().default(false),
};

const writing = defineCollection({
  loader: glob({ base: './src/content/writing', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    ...sharedFields,
    brand: z.literal('carlinis'),
  }),
});

const photo = defineCollection({
  loader: glob({ base: './src/content/photo', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    ...sharedFields,
    brand: z.literal('kine.miles'),
    cover: z.string().optional(),
    camera: z.string().optional(),
    lens: z.string().optional(),
    location: z.string().optional(),
    lat: z.number().optional(),
    lng: z.number().optional(),
  }),
});

const dev = defineCollection({
  loader: glob({ base: './src/content/dev', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    ...sharedFields,
    type: z.enum(['project', 'post']).default('post'),
    status: z.enum(['active', 'wip', 'archived']).optional(),
    stack: z.array(z.string()).default([]),
    repo: z.string().optional(),
    demo: z.string().optional(),
  }),
});

const music = defineCollection({
  loader: glob({ base: './src/content/music', pattern: '**/*.{md,mdx}' }),
  schema: z.object({
    ...sharedFields,
    artist: z.string().optional(),
    link: z.string().optional(),
    mediaType: z.enum(['audio', 'video', 'link']).optional(),
  }),
});

export const collections = { posts, writing, photo, dev, music };
