CREATE OR REPLACE FUNCTION get_user_friends(f_user_id INT)
RETURNS TABLE (
    friends_name VARCHAR(24)
    )
AS $$
BEGIN
    RETURN QUERY
    SELECT
    users.username FROM friends
    JOIN users ON friends.user_2_id = users.id
    WHERE friends.user_1_id = f_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE make_friends(p_user_1_id INT, p_user_2_id INT)
AS $$
BEGIN
    IF p_user_1_id = p_user_2_id
       THEN
           RAISE EXCEPTION 'a user cannot add them selves as friends!';
    END IF;

    INSERT INTO friends (user_1_id, user_2_id)
    VALUES (p_user_1_id, p_user_2_id);

    INSERT INTO friends (user_1_id, user_2_id)
    VALUES (p_user_2_id, p_user_1_id);

END;
$$ LANGUAGE plpgsql;
