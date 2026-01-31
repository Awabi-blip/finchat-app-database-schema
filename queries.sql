INSERT INTO users (username, password, display_name, badge, status, verified) VALUES
('awabi', 'pass1', 'chico', 'The Architect', 'Electric', TRUE),
('jenny', 'pass2', 'adriana lima', 'Eclipse', 'Sensory Overload', TRUE),
('zoya', 'pass3', 'aspie queen', 'Void Cat', 'Electric', TRUE),
('bom', 'pass4', 'bestie', 'Pixel Perfect', 'Moon Walking', TRUE),
('ifif', 'pass5', 'fifi', 'Vanilla Latte', 'Active', FALSE);

INSERT INTO servers (server_name, display_name, description, security_level)
VALUES
('royocherents', 'royocherents', 'our cutesty pootesy server tehee', 'Level 2'),
('goliathus', 'goliathus', 'electricity and green also white and black tehee', 'Level 1');

INSERT INTO users_in_servers(user_id, server_id, role_id)
VALUES (
(SELECT id FROM users WHERE username = 'awabi'),
(SELECT id FROM servers WHERE server_name = 'royocherents'),
3),
(
(SELECT id FROM users WHERE username = 'awabi'),
(SELECT id FROM servers WHERE server_name = 'goliathus'),
2),
(
(SELECT id FROM users WHERE username = 'jenny'),
(SELECT id FROM servers WHERE server_name = 'royocherents'),
3),
(
(SELECT id FROM users WHERE username = 'jenny'),
(SELECT id FROM servers WHERE server_name = 'goliathus'),
2),
(
(SELECT id FROM users WHERE username = 'bom'),
(SELECT id FROM servers WHERE server_name = 'goliathus'),
1);

INSERT INTO users_in_servers(user_id, server_id) VALUES(
(SELECT id FROM users WHERE username = 'zoya'),
(SELECT id FROM servers WHERE server_name = 'royocherents')
),
(
(SELECT id FROM users WHERE username = 'bom'),
(SELECT id FROM servers WHERE server_name = 'royocherents')
),
(
(SELECT id FROM users WHERE username = 'ifif'),
(SELECT id FROM servers WHERE server_name = 'royocherents')
);

--Since ifif is not verified, when i try to add them in royocherents, it adds null because of the
--check function

SELECT * FROM get_server_members((SELECT id FROM servers WHERE server_name = 'royocherents'));
SELECT * FROM get_server_members((SELECT id FROM servers WHERE server_name = 'goliathus'));

-- since server_name has a unique constraint, there wouldnt be any duplicate rows!

INSERT INTO messages_in_servers (user_id, server_id, message)
VALUES
(1,1, 'David Malan is not just a great professor, but a good motivator aswell as a kind human being, it seems to me!'),
(1,1, 'I have a crush on you!'),
(3,1, 'On who?!, me?'),
(1,1, 'Stick until the next project to find out'),
(3,1, 'Sigh youre so annoying'),
(4,1, 'Guys dont let this distract you from the fact that Carter taught an amazing course!'),
(2,2, 'im the mog lord!'),
(1,2, 'nah uh');

SELECT * from custom_sm;

CALL delete_messages(5,1,1);
-- success, awabi deletes zoya's youre so annoying easily abusing his admin prowess
CALL delete_messages(7,1,2);
-- 2 Error Check: Awabi tries to delete Jenny's message in Server 2, should fail cus hes only member

CALL make_friends(1,3);
CALL make_friends(1,4);
CALL make_friends(5,1);

SELECT * FROM get_user_friends(1);
SELECT * FROM get_server_members(1);
SELECT * FROM get_user_servers(1);
SELECT * FROM get_user_servers(4);

CALL insert_points_balance(1, 10000);
CALL insert_points_balance(3, 5000);

SELECT * FROM view_user_balance;
SELECT * FROM g_t_logs;
SELECT * FROM view_user_balance;

CALL make_gifts_transactions(1,3, 'weighted blanket');
CALL make_gifts_transactions(3,1, 'dim lights');

CALL make_points_transactions(1,4, 5000);
SELECT * FROM p_t_logs;
SELECT * FROM view_user_balance;

CALL make_points_transactions(5,3, 6500);

SELECT * from custom_sm;
SELECT * FROM show_audit_logs((SELECT "id" FROM "servers" WHERE "server_name" = 'royocherents'));
