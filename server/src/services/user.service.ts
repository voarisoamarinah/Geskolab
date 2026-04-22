import bcrypt from 'bcryptjs';
import prisma from '../lib/prisma.js';
import { CreateUserInput, UpdateUserInput } from '../validations/user.validation.js';

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

const userSelection = {
    id: true,
    username: true,
    role_id: true,
    status: true,
    created_at: true,
};

export const findAllUsers = async () => {
    return prisma.users.findMany({ select: userSelection });
};

export const findUserById = async (id: number) => {
    return prisma.users.findUnique({
        where: { id },
        select: userSelection,
    });
};

export const updateUser = async (id: number, data: UpdateUserInput) => {
    const updateData: any = { ...data };
    
    if (data.password) {
        const salt = await bcrypt.genSalt(10);
        updateData.password_hash = await bcrypt.hash(data.password, salt);
        delete updateData.password;
    }

    return prisma.users.update({
        where: { id },
        data: updateData,
        select: userSelection,
    });
};

export const deleteUser = async (id: number) => {
    return prisma.users.delete({ where: { id } });
};