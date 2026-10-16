import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { UserRepository } from '../repositories/UserRepository';

const userRepository = new UserRepository();

export class AuthController {
  async register(req: Request, res: Response): Promise<void> {
    try {
      const { nome, email, senha, cpf, telefone, tipo_perfil } = req.body;

      if (!nome || !email || !senha) {
        res.status(400).json({ error: 'Nome, email e senha são obrigatórios.' });
        return;
      }

      const userExists = await userRepository.findByEmail(email);
      if (userExists) {
        res.status(400).json({ error: 'E-mail já cadastrado.' });
        return;
      }

      const senhaHash = await bcrypt.hash(senha, 10);
      const newUser = await userRepository.create({
        nome,
        email,
        senhaHash,
        cpf,
        telefone,
        tipo_perfil: tipo_perfil || 'CLIENTE',
      });

      res.status(201).json({ message: 'Usuário registrado com sucesso!', user: newUser });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Erro ao registrar usuário no servidor.' });
    }
  }

  async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, senha } = req.body;

      const user = await userRepository.findByEmail(email);
      if (!user) {
        res.status(401).json({ error: 'Credenciais inválidas.' });
        return;
      }

      const passwordMatch = await bcrypt.compare(senha, user.senha);
      if (!passwordMatch) {
        res.status(401).json({ error: 'Credenciais inválidas.' });
        return;
      }

      const secret = process.env.JWT_SECRET || 'secret';
      const token = jwt.sign(
        { id: user.id_usuario, email: user.email, tipo_perfil: user.tipo_perfil },
        secret,
        { expiresIn: '1d' }
      );

      res.json({
        message: 'Login realizado com sucesso!',
        token,
        user: {
          id: user.id_usuario,
          nome: user.nome,
          email: user.email,
          tipo_perfil: user.tipo_perfil,
        },
      });
    } catch (error) {
      res.status(500).json({ error: 'Erro ao realizar login.' });
    }
  }
}