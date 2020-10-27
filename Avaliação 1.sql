/*1 - Faça uma VIEW que mostre todos os clientes que compraram da empresa no ano de 2020, bem como total que eles compraram.*/
CREATE VIEW V_SHOW_TOTAL_CLIENTE (NOME, TOTAL)
AS
SELECT C.NOME, SUM(IV.TOTAL)
FROM ITENS_VENDA IV
INNER JOIN VENDA V ON IV.ID_VENDA = V.ID_VENDA
INNER JOIN CLIENTE C ON V.ID_CLIENTE = C.ID_CLIENTE
WHERE YEAR(V.DATA_VENDA) = 2020 AND V.FINALIZADA = 1
GROUP BY 1
ORDER BY 2 DESC;

/*2 - Faça uma STORED PROCEDURE que mostre, em um ano qualquer, o subtotal em compras, o total em descontos das compras, o subtotal em vendas, 
o total em descontos das vendas, o total em compras, o total em vendas e o saldo no ano (somatórios em R$). Agrupe pelo fornecedor e cliente.*/

DELIMITER //
CREATE PROCEDURE SP_CALC_COMPRAS_VENDAS(IN SP_ANO INT)
BEGIN
  DECLARE MAIS_LINHAS INT DEFAULT 0;
  DECLARE TOTAL_VENDAS DECIMAL(15,2);
  DECLARE TOTAL_COMPRAS DECIMAL(15,2);
  DECLARE NOME VARCHAR(100);
  DECLARE SUB_TOTAL DECIMAL(15,2);
  DECLARE DESCONTO DECIMAL(15,2);
  DECLARE TOTAL DECIMAL(15,2);
  DECLARE SALDO DECIMAL(15,2);

  DECLARE CURSOR_VENDAS CURSOR FOR SELECT C.NOME, SUM(V.SUB_TOTAL), (SUM(V.SUB_TOTAL)-SUM(V.TOTAL)) AS DESCONTO, SUM(V.TOTAL)
  FROM VENDA V
  INNER JOIN CLIENTE C ON C.ID_CLIENTE = V.ID_CLIENTE
  WHERE YEAR(V.DATA_VENDA) = SP_ANO AND V.TOTAL IS NOT NULL
  GROUP BY C.NOME
  ORDER BY V.SUB_TOTAL DESC;

  DECLARE CURSOR_COMPRAS CURSOR FOR SELECT F.RAZAO_SOCIAL, SUM(C.SUB_TOTAL), (SUM(C.SUB_TOTAL)-SUM(C.TOTAL)) AS DESCONTO, SUM(C.TOTAL)
  FROM COMPRA C
  INNER JOIN FORNECEDOR F ON F.ID_FORNEC = C.ID_FORNEC
  WHERE YEAR(C.DATA_COMPRA) = SP_ANO AND C.TOTAL IS NOT NULL
  GROUP BY F.RAZAO_SOCIAL
  ORDER BY C.SUB_TOTAL DESC;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET MAIS_LINHAS = 1;
  SET MAIS_LINHAS = 0;

  DROP TEMPORARY TABLE IF EXISTS RESULTADO;
  CREATE TEMPORARY TABLE RESULTADO (
    TP_OPERACAO VARCHAR(6),
    TP_NOME VARCHAR(100),
    TP_SUB_TOTAL DECIMAL(15,2),
    TP_DESCONTO DECIMAL(15,2),
    TP_TOTAL DECIMAL(15,2),
    TP_SALDO DECIMAL(15,2)
  );

  SELECT SUM(V.TOTAL) INTO TOTAL_VENDAS
  FROM VENDA V 
  WHERE YEAR(V.DATA_VENDA) = SP_ANO AND V.TOTAL IS NOT NULL;

  SELECT SUM(C.TOTAL) INTO TOTAL_COMPRAS
  FROM COMPRA C
  WHERE YEAR(C.DATA_COMPRA) = SP_ANO AND C.TOTAL IS NOT NULL;

  SET SALDO = TOTAL_VENDAS - TOTAL_COMPRAS;

  OPEN CURSOR_VENDAS;
  LOOP_VENDAS: LOOP FETCH CURSOR_VENDAS INTO NOME, SUB_TOTAL, DESCONTO, TOTAL;
    IF MAIS_LINHAS = 1 THEN
      LEAVE LOOP_VENDAS;
    END IF;

    INSERT INTO RESULTADO (TP_OPERACAO, TP_NOME, TP_SUB_TOTAL, TP_DESCONTO, TP_TOTAL, TP_SALDO)
    VALUES ('Venda', NOME, SUB_TOTAL, DESCONTO, TOTAL, SALDO);
  END LOOP LOOP_VENDAS;
  CLOSE CURSOR_VENDAS;

  SET MAIS_LINHAS = 0;

  OPEN CURSOR_COMPRAS;
  LOOP_COMPRAS: LOOP FETCH CURSOR_COMPRAS INTO NOME, SUB_TOTAL, DESCONTO, TOTAL;
    IF MAIS_LINHAS = 1 THEN
      LEAVE LOOP_COMPRAS;
    END IF;

    INSERT INTO RESULTADO (TP_OPERACAO, TP_NOME, TP_SUB_TOTAL, TP_DESCONTO, TP_TOTAL, TP_SALDO)
    VALUES ('Compra', NOME, SUB_TOTAL, DESCONTO, TOTAL, SALDO);
  END LOOP LOOP_COMPRAS;
  CLOSE CURSOR_COMPRAS;
  
  SELECT TP_OPERACAO AS 'Tipo Operação', TP_NOME AS 'Cliente/Fornecedor', TP_SUB_TOTAL AS 'Subtotal', TP_DESCONTO AS 'Desconto', TP_TOTAL AS 'Total', TP_SALDO AS 'Saldo' FROM RESULTADO;
  
  DROP TEMPORARY TABLE RESULTADO;
END;
// DELIMITER ;