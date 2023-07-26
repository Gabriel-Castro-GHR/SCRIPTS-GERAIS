SELECT '1-Data do Status Report:' || CHR(13)||CHR(10) || '   '  AS Tipo,
       CASE
           WHEN to_char((SELECT c.DT_HISTORICO FROM COM_CLIENTE_HIST c WHERE c.NR_SEQ_PROJETO = a.nr_sequencia AND c.nr_seq_tipo = 21)) IS NULL THEN 'Sem data report'
           ELSE to_char((SELECT c.DT_HISTORICO FROM COM_CLIENTE_HIST c WHERE c.NR_SEQ_PROJETO = a.nr_sequencia AND c.nr_seq_tipo = 21),'dd/mon/yyyy')
       END AS Valor
FROM PROJ_PROJETO a
WHERE a.nr_sequencia = :nr_seq_proj
-- AND a.nr_seq_cliente = :nr_seq_cliente
-- AND a.ie_status = :ie_status

UNION ALL

SELECT '2-Nome do Projeto:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
       a.DS_TITULO AS Valor
FROM PROJ_PROJETO a
WHERE a.nr_sequencia = :nr_seq_proj
-- AND a.nr_seq_cliente = :nr_seq_cliente
-- AND a.ie_status = :ie_status

UNION ALL

SELECT '3-Data de Início:' || CHR(13)||CHR(10) || '   ' AS Tipo,
       CASE
           WHEN TO_CHAR(a.DT_INICIO_REAL, 'DD-mon-YYYY') IS NOT NULL THEN TO_CHAR(a.DT_INICIO_REAL, 'DD-mon-YYYY') || ' (real)'
           WHEN TO_CHAR(a.DT_INICIO_REAL, 'DD-mon-YYYY') IS NULL THEN
               CASE
                   WHEN TO_CHAR(a.DT_INICIO_PREV, 'DD-mon-YYYY') IS NOT NULL THEN TO_CHAR(a.DT_INICIO_PREV, 'DD-mon-YYYY') || ' (previsto)'
                   ELSE ' '
               END
           ELSE ' '
       END AS Valor
FROM PROJ_PROJETO a
WHERE a.nr_sequencia = :nr_seq_proj
-- AND a.nr_seq_cliente = :nr_seq_cliente
-- AND a.ie_status = :ie_status

UNION ALL

SELECT '4-Data prevista de finalização:' || CHR(13)||CHR(10) || '   ' AS Tipo,
       CASE
           WHEN TO_CHAR(a.DT_FIM_PREV, 'dd/mon/yyyy') IS NULL THEN 'Sem data de finalização prevista'
           ELSE TO_CHAR(a.DT_FIM_PREV, 'dd/mon/yyyy')
       END AS Valor
FROM PROJ_PROJETO a
WHERE a.nr_sequencia = :nr_seq_proj
-- AND a.nr_seq_cliente = :nr_seq_cliente
-- AND a.ie_status = :ie_status

UNION ALL

SELECT '5-Plataforma a ser migrada:'  || CHR(13)||CHR(10) || '   '   AS Tipo,
        CASE
           WHEN IE_HTML5 = 'S' AND IE_JAVA = 'N' AND IE_DELPHI = 'S' THEN 'HTML5,Delphi'
           WHEN IE_HTML5 = 'S' AND IE_JAVA = 'S' AND IE_DELPHI = 'S' THEN 'HTML5,Java,Delphi'
           WHEN IE_HTML5 = 'S' AND IE_JAVA = 'N' AND IE_DELPHI = 'N' THEN 'HTML5'
           WHEN IE_HTML5 = 'S' AND IE_JAVA = 'S' AND IE_DELPHI = 'N' THEN 'HTML5,Java'
           WHEN IE_HTML5 = 'N' AND IE_JAVA = 'S' AND IE_DELPHI = 'S' THEN 'Java,Delphi'
           WHEN IE_HTML5 = 'N' AND IE_JAVA = 'N' AND IE_DELPHI = 'S' THEN 'Delphi'
           ELSE 'Não Informado'
       END   AS Valor
FROM PROJ_PROJETO a
WHERE a.nr_sequencia = :nr_seq_proj
-- AND a.nr_seq_cliente = :nr_seq_cliente
-- AND a.ie_status = :ie_status
UNION ALL
SELECT '6-Equipe do projeto'  || CHR(13)||CHR(10) || '   ' AS Tipo,
       LISTAGG(
           (
               SELECT ds_funcao
               FROM PROJ_FUNCAO b
               WHERE b.nr_sequencia = a.NR_SEQ_FUNCAO
                 AND b.IE_SITUACAO = 'A'
           ) || obter_nome_pf(a.cd_pessoa_fisica),
           ': '
       ) WITHIN GROUP (ORDER BY a.NR_SEQ_FUNCAO) AS valor
FROM PROJ_EQUIPE_PAPEL a,
proj_equipe c
where c.nr_sequencia = a.nr_seq_equipe
and a.NR_SEQ_FUNCAO in (103,95,106,93)
and  c.nr_seq_proj = :nr_seq_proj
UNION ALL

SELECT '7-Equipe da GHR'  || CHR(13)||CHR(10) || '   ' AS Tipo,
       LISTAGG(
           (
               SELECT distinct ds_funcao
               FROM PROJ_FUNCAO b
               WHERE b.nr_sequencia = a.NR_SEQ_FUNCAO
                 AND b.IE_SITUACAO = 'A'
           )||  ': ' || obter_nome_pf(a.cd_pessoa_fisica)
        ) WITHIN GROUP (ORDER BY a.NR_SEQ_FUNCAO) AS valor
FROM PROJ_EQUIPE_PAPEL a,
proj_equipe c
where c.nr_sequencia = a.nr_seq_equipe
and a.NR_SEQ_FUNCAO in (98,92,107)
and  c.nr_seq_proj = :nr_seq_proj
UNION ALL
SELECT '8-Resumo do Cronograma:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
       LISTAGG(Valor, ' ') WITHIN GROUP (ORDER BY 1) AS Valor
FROM (
    SELECT
        '%Previsto: ' || CASE 
            WHEN B.QT_TOTAL_HORAS = 0 THEN '100%'
            ELSE B.PR_PREVISAO || '%' 
        END || ' | %Realizado: ' ||
        CASE 
            WHEN B.QT_HORAS_REALIZADO = 0 THEN '100%'
            ELSE ROUND(NVL(B.QT_HORAS_REALIZADO*100,0)/(B.QT_TOTAL_HORAS),2) || '%' 
        END || ' | Hrs Previstas: ' ||
        TO_CHAR(B.QT_TOTAL_HORAS) || ' | Hrs Realizadas: ' ||
        TO_CHAR(B.QT_HORAS_REALIZADO) ||' | %Desvio:' ||
        TO_CHAR(ROUND(B.pr_previsao-100, 2)) || '%' AS Valor
    FROM PROJ_PROJETO A
    JOIN PROJ_CRONOGRAMA B ON a.nr_sequencia = b.NR_SEQ_PROJ
    WHERE a.nr_sequencia = :nr_seq_proj
      AND b.ie_situacao = 'A'
) Subconsulta
UNION ALL
SELECT
    '9-OS ´s Críticas/Impactantes:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
    LISTAGG(
        NR_SEQ_ORDEM ,
        ' '
    ) WITHIN GROUP (ORDER BY NR_SEQ_ORDEM) AS Valor
FROM
        PROJ_ORDEM_SERVICO
WHERE nr_seq_proj = :nr_seq_proj
UNION ALL
SELECT '10-Documento fora do padrão, data de envio, número da OS de envio'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '11-Principais atividades entregues no mês/semana:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '12-Tipo, Riscos(ptos.de atenção), Plano de Ação, Criticidade, Responsávelmana:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '13-Documentos Migração, Data Envio Doc, Nro.OS:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '14-Milestone, Data Envio Doc, Nro.OS:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '15-Informativo obrigatório:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '16-Painel da documentação:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '17-Equipes e papéis:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '18-Lista de presença:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '19-Apresentação do review das atividades:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '20-Levantamento do Review na reunião de Status Report:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '21-Justificativa para review abaixo de 5:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '22-Itens não atendidos pelo Tasy - (buscar junto ao cliente):'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '23-Projeto Funcional:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '24-Total de atividades previstas:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '25-Total de atividades previstas por módulo:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '26-Total de atividades realizadas:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '27-Total de atividades realizadas por módulo:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '28-Comparativo de atividades previstas/realizadas:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '29-Comparativo de atividades previstas/realizadas por módulo:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '30-O que mais o Projeto Funcional pode entregar:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '31-Saldo de horas geral e por módulo:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '32-Auditoria Técnica:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '33-Evidências (planilha com os links):'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '34-Painel do Projeto:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '35-Geral:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '36-Atividades GHR:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '37-Atividades Cliente:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '38-Equipes e Papéis:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '39-Issues do projeto:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '40-Riscos do Projeto:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '42-Posicionamento dos Donos dos Processos:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '43-Entregáveis estratégicos e status de cada um:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '44-Cronograma MIG:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '45-Escopo Negativo:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '46-Curva de tendência por módulo:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '47-Questionamentos Philips (pesquisa):'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '48-Curva S:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '49-Estatística de Ordens de Serviço:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '50-OSs abertas, encerradas, total (Geral):'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '51-OSs abertas, encerradas, total (no período mensal/semanal):'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '52-OSs abertas, encerradas, total (anteriores ao período mensal/semanal):'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '53-BSC dos cadastros dos usuários:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '54-Visão GHR:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '55-Estratégico:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '56-Gerencial:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '57-Operacional:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '58-Entregáveis Estratégicos:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '59-Quantidade de EE:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
UNION ALL
SELECT '60-Quantidade de EE entregues:'  || CHR(13)||CHR(10) || '   ' AS Tipo,
'Sem informação' as Valor
FROM DUAL
