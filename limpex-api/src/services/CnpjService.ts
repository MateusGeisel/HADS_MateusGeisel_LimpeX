import axios from 'axios';

export interface CnpjResponseDTO {
  cnpj: string;
  razaoSocial: string;
  nomeFantasia: string;
  cnaeDescricao: string;
  situacaoCadastral: string;
  optanteMei?: boolean;
}

export class CnpjService {
  static async consultarCnpj(cnpj: string): Promise<CnpjResponseDTO | null> {
    const cleanCnpj = cnpj.replace(/\D/g, '');
    if (cleanCnpj.length !== 14) return null;

    try {
      // Consulta gratuita via BrasilAPI
      const response = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${cleanCnpj}`);

      return {
        cnpj: response.data.cnpj,
        razaoSocial: response.data.razao_social,
        nomeFantasia: response.data.nome_fantasia || response.data.razao_social,
        cnaeDescricao: response.data.cnae_fiscal_descricao,
        situacaoCadastral: response.data.descricao_situacao_cadastral,
        optanteMei: response.data.opcao_pelo_mei ?? false,
      };
    } catch (error) {
      console.error('Erro ao consultar CNPJ via BrasilAPI:', error);
      return null;
    }
  }
}