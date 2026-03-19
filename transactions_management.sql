
CREATE OR REPLACE PROCEDURE insert_points_balance(p_user_id INT, p_amount DECIMAL(8,2))
AS $$
DECLARE
p_verified BOOLEAN;
BEGIN
    p_verified := (SELECT verified FROM users WHERE id = p_user_id FOR UPDATE);

    IF p_verified = FALSE THEN
        RAISE EXCEPTION 'this action cannot be done';
    END IF;

    INSERT INTO points_balance (user_id, balance)
    VALUES (p_user_id, p_amount);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE make_points_transactions(p_sender_id INT, p_receiver_id INT, p_amount_sent DECIMAL(8,2))
AS $$
DECLARE
p_sender_balance NUMERIC;
BEGIN
    IF p_amount_sent <= 0 THEN
        RAISE EXCEPTION
            'not possible';
    END IF;

    -- ADDED this to lock both rows upon transaction's start. This locks sender and reciever both to prevent deadlocks
    -- Imagine a scanerio where line 285 runs and it locks the sender, and then in another transaction, sender is the receiver
    -- and the row is locked for that sender, and imagine that the sender in that transaction is the receiver in this transaction
    -- that puts a deadlock.
    -- TRANSACTION A: Awab sender, Zoya Receiver
    -- SELECT FOR UPDATE AWAB -> Awab gets locked, 
    -- TRANSACTION B: Zoya sender, Awab Reciever
    -- SELECT FOR UPDATE Zoya -> Zoya gets locked,
    -- CODE in TRANSACTION A reaches "UPDATE SEND BALANCE += AMOUNT WHERE USER IS ZOYA but zoya is locked"
    -- CODE in TRANSACTION B reached "UPDATE SEND BALANCE += AMOUNT WHERE USER IS AWAB but awab is locked"
    -- BOTH transactions come at a halt, because they can't go ahead, and this is a deadlock, so we lock both rows to begin with
    -- SELECT FOR UPDATE WORKS differently, it's locking as it is reading, because things are stored at different sectors in the disk, 
    -- Imagine a case scanerio : Awab wins starts the query and Zoya starts the query at roughly 1ms apart
    -- Now lets consider the time to run the queries, so Transaction A where Awab is sender, sends money to Zoya so sender is awab and 
    -- receiver is Zoya, sender_id (Awab) gets locked at this instant, the 0.1ms when Zoya started the transaction, she locks her self because
    -- she is the sender here, so technically she comes first, now when awab tries to lock zoya, (really what hes doing hes just selecting her
    -- but PERFORM 1 is discarding the result, so when awab tries to read her after 0.2ms from his initial query, zoya is already locked, and
    -- 0.1 ms after that zoya tries to read awab and lock him -> but there is a lock already there, now both queries cant process, because they are
    -- waiting for locks to be released, but both queries literally don't process ahead because they rely on each other.
    -- Time LINE :
    -- t = 0 : Awab locks himself
    -- t = 1 : Zoya locks her self
    -- t = 2 : awab tries to lock zoya but she is already locked
    -- t = 3 : zoya tries to lock but she is already locked
    -- DEADLOCK since both queries are now at blink, waiting for each of them to finish but they wont run since they rely on each other
    -- To solve this issue: we add a ORDER BY id (learnt, it did not come to me intuitively unfortunately tho i wish i did):
    -- So when we say FOR UPDATE database as soon as it finds something it locks it, but if we LITERALLY say ORDER BY, it moves it's
    -- Pointer in such a way that lower value comes first, so the lower value always get's locked first. NO matter the order of operations
    -- Transaction A : (Awab, Zoya) (sender, reciever)
    -- Transaction B : (Zoya, Awab) (sender, receiver)
    -- ORDER BY (id orlets say name)
    -- Awab locks Awab in the first query, even if it takes extra time for Transaction B to find Awab, it will find it first,
    -- so Awab locked himself, when zoya tries to lock him, she can not but Awab can lock zoya now BECAUSE zoya has not locked her self yet.
    -- So Transaction B is now on a lock but transaction A can continue, transaction A commits, then transaction B continues, because Awab
    -- is now unlocked, considering there were not any other transactions trying to access Awab, that happened before transaction B, based on
    -- the race condition, the row is unlocked and it is given to the user looking for it.
    -- LET'S just say Awab wins the race and applies the lock, first, even if it takes him forever to lock Zoya,
    -- the bidirectional can not be blocked because now in our database world HE ALWAYS locks himself before someone who comes after this name,
    -- If he was sending money to Aman, who comes before him, then he locks Aman first, and if Aman tried to send Awab money, She locks herself first,
    -- since awab locked her first, she cant do it and shes now on a wait, but what happens if now Zoya finds Awab before Awab processes Awab in the Aman situation?
    -- THEN awab is at a lock not a deadlock, because Zoya processed awab before, sends him money, and then awab can send Aman. I think thats a nice
    -- way to put this.

    PERFORM 1 FROM points_balance WHERE user_id IN (p_sender_id, p_receiver_id) ORDER BY (user_id) FOR UPDATE;
    
    p_sender_balance := (SELECT balance FROM points_balance WHERE user_id = p_sender_id FOR UPDATE);

    IF p_sender_balance IS NULL THEN
        RAISE EXCEPTION 'no balance added, hence no transactions must take place, fair as all things must be. period.';
    END IF;

    IF p_sender_balance <= 0 OR P_sender_balance < p_amount_sent THEN
        RAISE EXCEPTION 'not enough balance';
    END IF;

    UPDATE points_balance
    SET balance = balance - p_amount_sent
    WHERE user_id = p_sender_id;

    UPDATE points_balance
    SET balance = balance + p_amount_sent
    WHERE user_id = p_receiver_id;

    INSERT INTO points_transactions (sender_id, receiver_id, amount_sent)
    VALUES
    (p_sender_id, p_receiver_id, p_amount_sent);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE make_gifts_transactions(p_sender_id INT, p_receiver_id INT, p_gift_type gifts)
AS $$
DECLARE
p_gift_price DECIMAL(7,2);
p_sender_balance DECIMAL(8,2);
p_valid_gift gifts;
BEGIN

    p_valid_gift := (SELECT type FROM gift_inventory WHERE type = p_gift_type);

    IF p_valid_gift IS NULL THEN
        RAISE EXCEPTION 'no such gift';
    END IF;

    p_sender_balance := (SELECT balance FROM points_balance WHERE user_id = p_sender_id FOR UPDATE);

    IF p_sender_balance IS NULL THEN
        RAISE EXCEPTION 'no balance added, hence no transactions must take place, fair as all things must be. period.';
    END IF;

    p_gift_price := (SELECT price FROM gift_inventory WHERE type = p_gift_type);

    IF p_sender_balance <= 0 OR p_sender_balance < p_gift_price THEN
    -- Dev Note: nya ichi ni saaan nia arigato in pokimane style mwah mwah (RIP)
        RAISE EXCEPTION 'not enough balance';
    END IF;


    UPDATE points_balance
    SET balance = balance - p_gift_price
    WHERE user_id = p_sender_id;

    INSERT INTO gifts_transactions
    (sender_id, receiver_id, gift_type)
    VALUES (p_sender_id, p_receiver_id, p_gift_type);
END;
$$ LANGUAGE plpgsql;


CREATE VIEW "p_t_logs" AS
SELECT
    senders.username AS sender,
    receivers.username AS receiver,
    points_transactions.amount_sent
FROM
    points_transactions
JOIN users AS senders
    ON senders.id = points_transactions.sender_id
JOIN users AS receivers
    ON receivers.id = points_transactions.receiver_id
;

CREATE VIEW "g_t_logs" AS
SELECT
    senders.username AS sender,
    receivers.username AS receiver,
    gifts_transactions.gift_type
FROM
    gifts_transactions
JOIN users AS senders
    ON senders.id = gifts_transactions.sender_id
JOIN users AS receivers
    ON receivers.id = gifts_transactions.receiver_id
;

CREATE VIEW view_user_balance AS
SELECT users.username, points_balance.balance
FROM points_balance JOIN users
ON points_balance.user_id = users.id;
-- CREATE OR REPLACE FUNCTION user_gifts_transactions_logs(
-- f_user_id INT)
-- RETURNS TABLE(
-- sender_name VARCHAR(24),
-- receiver_name VARCHAR(24),
-- gift_type gifts,
-- gift_price DECIMAL(5,2)
-- ) AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT
--     (SELECT username FROM users WHERE id = f_user_id) AS "sender_name",
--     users.username,
--     gifts_transactions.gift_type, gift_inventory.price
--     FROM gifts_transactions
--     JOIN users ON users.id =
--     gifts_transactions.receiver_id
--     JOIN gift_inventory ON gift_inventory.gift_type
--     = gifts_transactions.gift_type
--     WHERE gifts_transactions.sender_id = f_user_id;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE OR REPLACE FUNCTION user_points_transactions_logs(
-- f_user_id INT)
-- RETURNS TABLE(
--     sender_name VARCHAR(24),
--     receiever_name VARCHAR(24),
--     amount_sent DECIMAL(8,2)
-- ) AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT
--     (SELECT username FROM users WHERE id = f_user_id) AS "sender_name",
--     users.username, points_transactions.amount_sent
--     FROM points_transactions JOIN users
--     ON users.id = points_transactions.receiver_id
--     WHERE sender_id = f_user_id;
-- END;
-- $$ LANGUAGE plpgsql;
