import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export const requireAuth = (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;

    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ message: "Accès refusé. Token manquant." });
    }

    try {
        const secret = process.env.JWT_SECRET || "votre_clé_secrète_par_défaut";
        const decoded = jwt.verify(token, secret) as { userId: number; role: string };

        (req as any).user = decoded;

        next();
    } catch (error) {
        return res.status(403).json({ message: "Token invalide ou expiré." });
    }
};

export const requireRole = (role: string) => {
    return (req: Request, res: Response, next: NextFunction) => {
        const user = (req as any).user;

        if (!user || user.role !== role) {
            return res.status(403).json({
                message: `Accès interdit.`
            });
        }
        next();
    };
};