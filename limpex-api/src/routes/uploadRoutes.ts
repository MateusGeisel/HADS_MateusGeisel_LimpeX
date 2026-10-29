import { Router } from 'express';
import { upload } from '../middlewares/upload';
import { supabase } from '../config/supabase';

const uploadRouter = Router();

uploadRouter.post('/', upload.single('imagem'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhuma imagem foi enviada.' });
    }

    const file = req.file;
    const fileExt = file.originalname.split('.').pop();
    const fileName = `${Date.now()}.${fileExt}`;

    // Envia o ficheiro em memória para o Supabase Storage
    const { error } = await supabase.storage
      .from('limpex-imagens')
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
      });

    if (error) {
      return res.status(500).json({ error: 'Erro ao guardar a imagem no Supabase: ' + error.message });
    }

    // Obter a URL pública da imagem enviada
    const { data } = supabase.storage
      .from('limpex-imagens')
      .getPublicUrl(fileName);

    return res.status(200).json({ url: data.publicUrl });
  } catch (err: any) {
    return res.status(500).json({ error: err.message || 'Erro no servidor.' });
  }
});

export default uploadRouter;