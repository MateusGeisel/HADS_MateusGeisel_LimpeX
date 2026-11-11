import multer from 'multer';

// Salva o arquivo na memória RAM para enviar o Buffer ao Supabase
const storage = multer.memoryStorage();

export const upload = multer({ storage });