-- Función del trigger ya que PostgreSQL 
CREATE OR REPLACE FUNCTION validacion_invoice_line()
RETURNS TRIGGER AS $$
DECLARE
    precioActual numeric(12,2);
BEGIN
    -- Utilizamos NEW. que sirve para obtener el precio del producto según el id que está tratando de ser insertado
    SELECT unit_price INTO precioActual
    FROM public.products 
    WHERE id = NEW.product_id;
    
    -- Validar que el unit_price sea igual al precio actual del producto
    IF NEW.unit_price != precioActual THEN
        RAISE EXCEPTION 'El precio unitario (%) no coincide con el precio actual del producto (%)', NEW.unit_price, precioActual;
    END IF;
    
    -- Validar que line_total sea igual a quantity * unit_price
    IF NEW.line_total != (NEW.quantity * NEW.unit_price) THEN
        RAISE EXCEPTION 'El total de línea (%) no coincide con quantity (%) * unit_price (%)', NEW.line_total, NEW.quantity, NEW.unit_price;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; -- Esta parte nos permite utilizar instrucciones extras, como IF

-- Crear el trigger
CREATE TRIGGER trigger_validacion_invoice_line
    BEFORE INSERT OR UPDATE ON public.invoice_lines
    FOR EACH ROW
    EXECUTE FUNCTION validacion_invoice_line();
