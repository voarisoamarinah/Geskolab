import { z } from 'zod';

export const createUser = z.object({
    body: z.object({
        username: z
            .string("Le nom d'utilisateur est requis")
            .min(3, "Trop court (min 3 caractères)"),
        password: z
            .string("Le mot de passe est requis")
            .min(6, "Le mot de passe doit contenir au moins 6 caractères"),
        role_id: z.number("Le role_id est obligatoire"),
        status: z.enum(['active', 'inactive', 'suspended']).optional().default('active'),
    }),
});

export const updateUser = z.object({
    params: z.object({
        id: z.string().transform((val) => parseInt(val, 10)),
    }),
    body: z.object({
        username: z.string().min(3).optional(),
        password: z.string().min(6).optional(),
        role_id: z.number().optional(),
        status: z.enum(['active', 'inactive', 'suspended']).optional(),
    }).strict(),
});

export const userId  = z.object({
    params: z.object({
        id: z.string().transform((val) => parseInt(val, 10)),
    }),
});

export type UpdateUserInput = z.infer<typeof updateUser>['body'];
export type CreateUserInput = z.infer<typeof createUser>['body'];