import pandas as pd
import sys

# Verificar se o argumento foi passado
if len(sys.argv) != 2:
    print("Erro: variavel não informada.")
    print("Chamada Correta: python kyno_create_files_plan_hash.py ALIAS_DB")
    sys.exit(1)

v_dbname = sys.argv[1]

df = pd.read_csv(f'/home/oracle/kyno/logs/kyno_monitor_plan_hash_{v_dbname}.csv', sep=';')
df["melhora"] = df["melhora"].str.replace("%", "")
df['melhora'] = df['melhora'].astype(float)
df = df.sort_values('melhora', ascending=False)

# Iniciar o HTML
html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>Botão com Ação</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid black;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .button {
            background-color: #4CAF50; /* Verde */
            border: none;
            color: white;
            padding: 10px 20px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 16px;
            margin: 4px 2px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <h1>Relatório de Performance SQLID</h1>
    <table>
        <tr>
            <th>Os Plan Hash Value atuais para os SQLID abaixo estao com performance degradada</th>
            <th>Action</th>
        </tr>
"""
# Iniciar o TXT
txt_content = f"""Relacao de SQLID's com alteracao de plano com degradacao na performance - {v_dbname}.


"""

# Adicionar cada linha do DataFrame como uma linha da tabela

for i, linha in df.iterrows():
    # HTML
    html_content += f"""
        <tr>
            <td>{f"SQLID: {linha['sqlid']}"}
                <br>
                {f"Plan_Hash Atual : {linha['hash_atual']} - AVG Time : {linha['avg_time_atual']} - Data Load : {linha['dt_load_atual']}"}
                <br>
                {f"Plan_Hash Melhor: {linha['hash_melhor']} - AVG Time : {linha['avg_time_melhor']} - Data Load : {linha['dt_load_melhor']}"}
                <br>
                {f"Diferença: {linha['diff']}"}
                <br>
                {f"Acrescimo de {linha['melhora']}%"}
            </td>
            <td>
                <button class="button" onclick="performAction('{linha['sqlid']}')">Corrigir</button>
            </td>
        </tr>
    """
    # TXT
    txt_content += f"""SQLID: {linha['sqlid']}
Plan_Hash Atual : {linha['hash_atual']} - AVG Time : {linha['avg_time_atual']} - Data Load : {linha['dt_load_atual']}
Plan_Hash Melhor: {linha['hash_melhor']} - AVG Time : {linha['avg_time_melhor']} - Data Load : {linha['dt_load_melhor']}
Diferença: {linha['diff']}
Acrescimo de {linha['melhora']}%
--------------------------------
--------------------------------
"""   

# Fechar o HTML
html_content += """
    </table>

    <script>
        function performAction(sqlid) {
            alert("Ação executada para o SQLID: " + sqlid);
           // Adicionar nova função para chamada do Rundeck
        }
    </script>
</body>
</html>
"""

# Salvar o HTML em um arquivo
with open(f'/var/www/html/files/relatorio_performance_{v_dbname}.html', 'w', encoding='utf-8') as file:
    file.write(html_content)

# Salvar o TXT em um arquivo
with open(f'/home/oracle/kyno/logs/kyno_monitor_plan_hash_{v_dbname}.log', 'w', encoding='utf-8') as file:
    file.write(txt_content)

print("Arquivos Gerados:")
print(f"/var/www/html/files/relatorio_performance_{v_dbname}.html")
print(f"/home/oracle/kyno/logs/kyno_monitor_plan_hash_{v_dbname}.log")