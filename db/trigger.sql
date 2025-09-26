-- Trigger que calcula el total de la línea de factura al insertar una nueva línea
-- y asegura que el precio unitario se obtiene de la tabla de productos.

CREATE TRIGGER trigger_invoice_validation
ON invoice_lines
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO invoice_lines (invoice_id, product_id, quantity, unit_price, line_total)
    SELECT
        i.invoice_id,
        i.product_id,
        i.quantity,
        p.unit_price,
        i.quantity * p.unit_price
    FROM inserted i
    INNER JOIN products p ON i.product_id = p.id;
END;