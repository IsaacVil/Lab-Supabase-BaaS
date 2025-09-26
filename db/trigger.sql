-- Función de Disparo para calcular el total de la línea de factura
CREATE OR REPLACE FUNCTION calculate_invoice_line_total()
RETURNS TRIGGER AS $$
DECLARE
    v_unit_price NUMERIC;
BEGIN
    SELECT unit_price INTO v_unit_price
    FROM products
    WHERE id = NEW.product_id;

    NEW.unit_price := v_unit_price;
    NEW.line_total := NEW.quantity * NEW.unit_price;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creación del Disparador
CREATE TRIGGER trigger_invoice_validation
BEFORE INSERT ON invoice_lines
FOR EACH ROW
EXECUTE FUNCTION calculate_invoice_line_total();
