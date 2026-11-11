import { Router } from 'express';
import { upload } from '../middlewares/upload';
import { supabase } from '../config/supabase';

const uploadRouter = Router();

uploadRouter.post('/', upload.single('imagem'), async (req, res) => {
  try {
    if (!req.file) {
      console.log('❌ Nenhum arquivo enviado na requisição.');
      return res.status(400).json({ error: 'Nenhuma imagem foi enviada.' });
    }

    const file = req.file;
    const fileExt = file.originalname.split('.').pop();
    const fileName = `${Date.now()}.${fileExt}`;

    console.log(`📤 Tentando subir imagem: ${fileName}`);

    // Envia para o Supabase Storage
    const { error } = await supabase.storage
      .from('limpex-imagens')
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: true,
      });

    if (error) {
      console.error('❌ Erro retornado pelo Supabase:', error.message);
      return res.status(500).json({ error: 'Erro no Supabase: ' + error.message });
    }

    // Pega a URL pública
    const { data } = supabase.storage
      .from('limpex-imagens')
      .getPublicUrl(fileName);

    console.log('✅ Imagem salva com sucesso! URL:', data.publicUrl);
    return res.status(200).json({ url: data.publicUrl });

  } catch (err: any) {
    console.error('❌ Erro interno:', err.message);
    return res.status(500).json({ error: err.message || 'Erro no servidor.' });
  }
});

export default uploadRouter;