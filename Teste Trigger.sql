DELIMITER // 
CREATE TRIGGER T_CALCULA_DESCONTO_VENDA_BI
BEFORE INSERT ON VENDA
FOR EACH ROW
BEGIN
	DECLARE QTD_VENDAS INT;
	
	SELECT COUNT(V.ID_VENDA) INTO QTD_VENDAS
	FROM VENDA V
	WHERE V.ID_CLIENTE = NEW.ID_CLIENTE AND V.FINALIZADA;
	
	IF (QTD_VENDAS >= 2 AND QTD_VENDAS <= 9) THEN
		SET NEW.DESCONTO = 5;
	ELSEIF (QTD_VENDAS >= 10 AND QTD_VENDAS <= 24) THEN
		SET NEW.DESCONTO  = 10;
	ELSEIF (QTD_VENDAS >= 25 AND QTD_VENDAS <= 36) THEN
		SET NEW.DESCONTO = 15;
	ELSEIF (QTD_VENDAS > 36) THEN
		SET NEW.DESCONTO = 20;
	ELSE
		SET NEW.DESCONTO = 0;
	END IF;
END;
//DELIMITER ;