import { Request, Response } from 'express';
import * as AuthService from '../services/auth.service.js';

export const loginHandler = async (req: Request, res: Response) => {
    try {
        const result = await AuthService.loginUser(req.body);
        return res.status(200).json(result);
    } catch (error: any) {
        return res.status(401).json({ message: error.message });
    }
};