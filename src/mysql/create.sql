use ic;
set sql_mode="ANSI_QUOTES";

drop table if exists dominios;
create table dominios (
  id bigint(20) not null auto_increment primary key,
  dominio varchar(255)
);

drop table if exists imap_connector;
create table imap_connector (
  id int not null default null auto_increment primary key,
  id_domain bigint(20) unsigned not null references dominios(id) on delete restrict on update cascade,
  server varchar(255) not null,
  port varchar(20) not null default 143,
  protocol varchar(20) not null default 'IMAP',
  "user" varchar(255) not null,
  password varchar(255) not null,
  folder varchar(255) not null default 'INBOX',
  post_archived_action int(1) not null default 1,
  "ssl" int(1) null default 1,
  state int(1) null default 1
);
