import { Request, Response } from 'express';
import * as UserService from '../services/user.service.js';
import { CreateUserInput, QueryUserInput } from '../validations/user.validation.js';

export const createUserHandler = async (
    req: Request<{}, {}, CreateUserInput>,
    res: Response
) => {
    try {
        const user = await UserService.createUser(req.body);
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

export const getUsersHandler = async (
    req: Request,
    res: Response
) => {
    try {
        const query = req.query as unknown as QueryUserInput;

        const result = await UserService.findAllUsers(query);
        return res.status(200).json(result);
    } catch (error) {
        console.error(error);
        return res.status(500).json({ message: "Erreur lors de la récupération" });
    }
};

export const getUserByIdHandler = async (req: Request, res: Response) => {
    const id = parseInt(req.params.id[0]);
    const user = await UserService.findUserById(id);
    if (!user) return res.status(404).json({ message: "Utilisateur non trouvé" });
    return res.status(200).json(user);
};

export const updateUserHandler = async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id[0]);
        const user = await UserService.updateUser(id, req.body);
        return res.status(200).json({ message: "Utilisateur mis à jour", user });
    } catch (error) {
        return res.status(500).json({ message: "Erreur lors de la mise à jour" });
    }
};

export const deleteUserHandler = async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id[0]);
        await UserService.deleteUser(id);
        return res.status(200).json({ message: "Utilisateur supprimé avec succès" });
    } catch (error) {
        return res.status(500).json({ message: "Erreur lors de la suppression" });
    }
};

export const toggleUserStatusHandler = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { status } = req.body;

    const user = await UserService.updateUser(parseInt(id[0]), { status });
    return res.status(200).json({ message: `Utilisateur désormais ${status}`, user });
};