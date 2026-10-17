import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { UserRepository } from '../repositories/UserRepository';

export class AuthController {
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const { nome, email, senha, telefone, tipo_perfil } = req.body;

      if (!nome || !email || !senha) {
        res.status(400).json({ error: 'Nome, e-mail e senha são obrigatórios.' });
        return;
      }

      // Chamada direta na classe (sem dar "new UserRepository()")
      const userExists = await UserRepository.findByEmail(email);
      if (userExists) {
        res.status(400).json({ error: 'E-mail já cadastrado.' });
        return;
      }

      const senhaHash = await bcrypt.hash(senha, 10);
      
      // Mapeia o perfil vindo do Flutter para o padrão da tabela 'perfil' no banco (CONTRATANTE / PRESTADOR)
      const perfilMapeado = (tipo_perfil === 'PRESTADOR') ? 'PRESTADOR' : 'CONTRATANTE';

      const newUser = await UserRepository.create({
        nome,
        email,
        senhaHash,
        telefone,
        tipo_perfil: perfilMapeado,
      });

      res.status(201).json({ 
        message: 'Usuário registrado com sucesso!', 
        user: newUser 
      });
    } catch (error) {
      console.error('Erro no registro:', error);
      res.status(500).json({ error: 'Erro ao registrar usuário no servidor.' });
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, senha } = req.body;

      if (!email || !senha) {
        res.status(400).json({ error: 'E-mail e senha são obrigatórios.' });
        return;
      }

      const user = await UserRepository.findByEmail(email);
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
        { 
          id: user.id_usuario, 
          email: user.email, 
          tipo_perfil: user.perfil_nome || 'CONTRATANTE' 
        },
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
          tipo_perfil: user.perfil_nome || 'CONTRATANTE',
        },
      });
    } catch (error) {
      console.error('Erro no login:', error);
      res.status(500).json({ error: 'Erro ao realizar login.' });
    }
  }
}