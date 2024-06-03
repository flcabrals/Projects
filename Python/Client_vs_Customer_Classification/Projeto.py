# -*- coding: utf-8 -*-
# Importando Bibliotecas | Complementar conforme for surgindo necessidades
import time
from time import gmtime
import pandas as pd
import os
import argparse
import sys
import datetime

# Configuração de Parametros
path = os.getcwd()
parser = argparse.ArgumentParser(description='Programa para Classificação de Clientes')
parser.add_argument('base_vendas',  nargs='?', help='1) Nome do Arquivo da Base de Vendas')
parser.add_argument('base_dicio',   nargs='?', help='2) Nome do Arquivo do Dicionario de/para')
parser.add_argument('base_produto', nargs='?', help='3) Nome do Arquivo da Base Produtos')
args = parser.parse_args()

# Formatação de data inicial / Mensagem de Inicio do Processamento
tempoinicial = time.time()
now = datetime.datetime.now()
ano = '{:02d}'.format(now.year)
mes = '{:02d}'.format(now.month)
dia = '{:02d}'.format(now.day)
hora = '{:02d}'.format(now.hour)
minuto = '{:02d}'.format(now.minute)
day_month_year = '{}/{}/{} {}:{}'.format(dia, mes, ano, hora, minuto)
print("Processamento Iniciado: "+day_month_year)
print('Aguarde...')

# Setando variavel df com o conteudo do dataset
if '.csv' in args.base_vendas:
    df_vendas = pd.read_csv(path+'/'+args.base_vendas, dtype={'id_cliente': 'string', 'id_item':'string'})
else:
    df_vendas = pd.read_excel(path+'/'+args.base_vendas, dtype={'id_cliente': 'string', 'id_item':'string'})
    
if '.csv' in args.base_dicio:
    df_dicio  = pd.read_csv(path+'/'+args.base_dicio)
else:
    df_dicio  = pd.read_excel(path+'/'+args.base_dicio)

if '.csv' in args.base_produto:
    df_prod   = pd.read_csv(path+'/'+args.base_produto)
else:
    df_prod   = pd.read_excel(path+'/'+args.base_produto)

# Criando dataframe final    
df_final  = pd.DataFrame(columns=['cliente','categoria','quantidade'])

# Pipe line de processamento dos dados
df_prod= df_prod.merge(df_dicio,how='left')
df_prod = df_prod[['ID_ITEM','De/Para Função']]
df_prod.rename({'ID_ITEM': 'id_item'}, inplace = True, axis='columns')
df_prod.rename({'De/Para Função': 'de_para'}, inplace = True, axis='columns')
df_prod.id_item = df_prod.id_item.astype('string')
df_vendas = df_vendas.merge(df_prod,how='left',on='id_item')

df_final = df_vendas.groupby(['id_cliente','de_para']).size().reset_index().rename(columns={0:'quantity'}).sort_values(['id_cliente','quantity'], ascending=False)
df_final_unico = df_final.groupby(['id_cliente']).head(1)
df_final = df_final.groupby(['id_cliente']).head(3)

df_final.to_csv(path+'/Dados_Final.csv',index=False)
df_final_unico.to_csv(path+'/Dados_Final_Unico.csv',index=False)

# Mensagem de Finalização do Processamento
print('')
print(f'Processamento Finalizado em {round(time.time() - tempoinicial)} segundos') 
print("Arquivos Gerados: Dados_Final.csv e Dados_Final_Unico.csv")
print('')
