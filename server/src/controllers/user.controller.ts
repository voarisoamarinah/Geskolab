import { Request, Response } from 'express';
import { createUser } from '../services/user.service.js';
import { CreateUserInput } from '../validations/user.validation.js';

export const createUserHandler = async (
    req: Request<{}, {}, CreateUserInput>,
    res: Response
) => {
    try {
        const user = await createUser(req.body);
        return res.status(201).json({
            message: "Utilisateur créé avec succès",
            user,
        });
    } catch (error: any) {
        if (error.code === 'P2002') {
            return res.status(409).json({ message: "Ce nom d'utilisateur existe déjà" });
        }
        console.error(error);
        return res.status(500).json({ message: "Erreur lors de la création" });
    }
};