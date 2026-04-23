import { z } from 'zod';

export const loginSchema = z.object({
    body: z.object({
        username: z.string().min(1, "Le nom d'utilisateur est requis"),
        password: z.string().min(1, "Le mot de passe est requis"),
    }),
});

export type LoginInput = z.infer<typeof loginSchema>['body'];