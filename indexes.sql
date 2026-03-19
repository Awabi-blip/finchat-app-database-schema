CREATE INDEX "users_index" ON "users"("username") INCLUDE ("verified");

CREATE INDEX "servers_index" ON "servers"("server_name") INCLUDE ("security_level");

CREATE INDEX "users_in_servers_index1" ON "users_in_servers"("server_id") INCLUDE ("user_id", "role_id");
CREATE INDEX "users_in_servers_index2" ON "users_in_servers"("user_id") INCLUDE ("server_id", "role_id");

CREATE INDEX "points_balance_index" ON "points_balance"("user_id") INCLUDE ("balance");
CREATE INDEX "points_transactions_index1" ON "points_transactions"("sender_id") INCLUDE ("receiver_id", "amount_sent");
CREATE INDEX "points_transactions_index2" ON "points_transactions"("receiver_id") INCLUDE ("sender_id", "amount_sent");

CREATE INDEX "messages_in_servers_index1" ON "messages_in_servers"("user_id") INCLUDE ("server_id", "is_deleted", "sent_at");
CREATE INDEX "messages_in_servers_index2" ON "messages_in_servers"("server_id") INCLUDE ("user_id", "is_deleted", "sent_at");

CREATE INDEX "audit_log_index" ON "audit_logs" ("server_id") INCLUDE ("message_id", "deleted_of_id", "deleted_by_id");
