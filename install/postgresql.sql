-- 20131001

CREATE OR REPLACE FUNCTION fn_temperature_historical()
  RETURNS trigger AS
$BODY$
BEGIN
    IF  TG_OP = 'INSERT' THEN
	IF NEW.temperature > 260 THEN
		INSERT INTO temperature_historical(tid, timestamp, temperature) values (NEW.tid, NEW.timestamp, NEW.temperature);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
	IF OLD.tid = NEW.tid AND OLD.temperature <> NEW.temperature AND NEW.temperature > 260 THEN
		INSERT INTO temperature_historical(tid, timestamp, temperature) values (NEW.tid, NEW.timestamp, NEW.temperature);
        END IF;
        RETURN NEW;        
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM temperature_historical where temperature_historical.tid=OLD.tid;
        RETURN OLD;        
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_temperature_historical()
  OWNER TO "QCRollingMill";





