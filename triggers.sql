CREATE OR REPLACE FUNCTION check_user_integrity()
RETURNS TRIGGER AS $$
DECLARE
    v_verification BOOLEAN;
    v_security_level TEXT;
BEGIN
    v_verification := (SELECT verified FROM users WHERE id = NEW.user_id);
    v_security_level := (SELECT security_level FROM servers WHERE id = NEW.server_id);

    IF v_verification = FALSE AND v_security_level = 'Level 2' THEN
         RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_user_integrity
BEFORE INSERT ON "users_in_servers"
FOR EACH ROW
EXECUTE FUNCTION check_user_integrity();
