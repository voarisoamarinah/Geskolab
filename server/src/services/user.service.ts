import bcrypt from 'bcryptjs';
import prisma from '../lib/prisma.js';
import { CreateUserInput } from '../validations/user.validation.js';

export const createUser = async (input: CreateUserInput) => {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(input.password, salt);

    return prisma.users.create({
        data: {
            username: input.username,
            password_hash: hashedPassword,
            role_id: input.role_id,
            status: input.status,
        },
        select: {
            id: true,
            username: true,
            role_id: true,
            status: true,
            created_at: true,
        },
    });
};