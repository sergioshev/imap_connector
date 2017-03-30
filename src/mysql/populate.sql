use ic;
set sql_mode="ANSI_QUOTES";

delete from dominios;
insert into dominios values 
  (1, 'termialquequen.com.ar'),
  (2, 'gmail.com'),
  (3, 'yahoo.com.ar');


delete from imap_connector;
insert into imap_connector (id_domain, server, port, protocol, "user", password, folder, "ssl", post_archived_action ) values
 (2, 'imap.gmail.com', 993, 'imap', 'sergioshev', '&f1xt1r3%', '[Gmail]/&BCEEPwQwBDw-', 1, 2 );
-- (2, 'imap.gmail.com', 143, 'imap', 'sergioshev', '&f1xt1r3%', default, 1, 2 ),
-- (1, 'imap.terminalquequen.com.ar', default, default, 'sshevtsov', 'fractalito', default, 0, 2);
-- (3, 'pop3.yahoo.com.ar', 110, 'pop3', 'sshevtsov', 'fractalito', default, 0, 2);

