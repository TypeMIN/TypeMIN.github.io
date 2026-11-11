import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const webUrl = z.url().refine(
  (value) => ['https:', 'http:'].includes(new URL(value).protocol),
  '앱과 저장소 주소에는 http 또는 https URL을 사용하세요.',
);

const projects = defineCollection({
  loader: glob({
    pattern: '*.md',
    base: './src/content/projects',
    generateId: ({ entry }) => {
      const slug = entry.replace(/\.md$/, '');
      if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) {
        throw new Error(`프로젝트 파일명은 영문 소문자·숫자·하이픈을 사용하세요: ${entry}`);
      }
      return slug;
    },
  }),
  schema: z.object({
    title: z.string().trim().min(1),
    summary: z.string().trim().min(1),
    tags: z.array(z.string().trim().min(1)).default([]),
    featured: z.boolean().default(false),
    appUrl: webUrl.optional(),
    repoUrl: webUrl.optional(),
  }),
});

export const collections = { projects };
