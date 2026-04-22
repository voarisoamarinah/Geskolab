import bcrypt from 'bcryptjs';
import prisma from '../lib/prisma.js';
import { CreateUserInput, UpdateUserInput, QueryUserInput } from '../validations/user.validation.js';

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

export const findAllUsers = async (query: QueryUserInput) => {
    const page = Number(query?.page) || 1;
    const limit = Number(query?.limit) || 10;
    const sortBy = query?.sortBy || 'created_at';
    const sortOrder = query?.sortOrder || 'desc';

    const skip = Math.max((page - 1) * limit, 0);

    const where: any = {};
    if (query?.username) {
        where.username = { contains: query.username, mode: 'insensitive' };
    }
    if (query?.role_id) {
        where.role_id = Number(query.role_id);
    }
    if (query?.status) {
        where.status = query.status;
    }

    const [users, total] = await Promise.all([
        prisma.users.findMany({
            where,
            take: limit,
            skip: skip,
            orderBy: {
                [sortBy]: sortOrder
            },
            select: userSelection,
        }),
        prisma.users.count({ where }),
    ]);

    return {
        data: users,
        meta: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        },
    };
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