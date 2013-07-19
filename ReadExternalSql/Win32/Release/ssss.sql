
-- Table: settings
CREATE TABLE settings ( 
    name  VARCHAR( 50 )   PRIMARY KEY
                          NOT NULL
                          UNIQUE,
    value VARCHAR( 256 ) 
);

INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::ip', 'localhost');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::user', 'sysdba');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::password', 'masterkey');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::db_name', 'C:\tmp\mc_250-5\MS5DB6.FDB');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::library', 'fbclient.dll');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::ip', 'krr-sql13');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::user', 'asutpadp');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::password', 'dc1');
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::db_name', 'ovp68');
INSERT INTO [settings] ([name], [value]) VALUES ('::FbSql::dialect', 3);
INSERT INTO [settings] ([name], [value]) VALUES ('::OraSql::port', 1521);
INSERT INTO [settings] ([name], [value]) VALUES ('::OPC::server_name', 'Krug.OPCServer.1');
INSERT INTO [settings] ([name], [value]) VALUES ('::OPC::tag_temp_left', 'VA.TE4_2');
INSERT INTO [settings] ([name], [value]) VALUES ('::OPC::tag_temp_right', 'VA.TE3_4');
INSERT INTO [settings] ([name], [value]) VALUES ('::RollingMill::number', 5);
INSERT INTO [settings] ([name], [value]) VALUES ('::TCP::remote_ip', 'localhost');
INSERT INTO [settings] ([name], [value]) VALUES ('::TCP::remote_port', 33333);
