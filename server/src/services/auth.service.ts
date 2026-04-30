import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../lib/prisma.js';
import { LoginInput } from '../validations/auth.validation.js';

export const loginUser = async (input: LoginInput) => {
    const user = await prisma.users.findUnique({
        where: { username: input.username },
        include: { roles: true } 
    });

    if (!user || user.status !== 'active') {
        throw new Error("Utilisateur non trouvé ou compte inactif");
    }

    const isPasswordValid = await bcrypt.compare(input.password, user.password_hash);
    if (!isPasswordValid) {
        throw new Error("Mot de passe incorrect");
    }

    const token = jwt.sign(
        {
            userId: user.id,
            role: user.roles.name
        },
        process.env.JWT_SECRET || 'super_secret_key',
        { expiresIn: '1h' }
    );

    return {
        token,
        user: {
            id: user.id,
            username: user.username,
            role: user.roles.name
        }
    };
};