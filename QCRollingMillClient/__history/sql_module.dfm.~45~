object Module: TModule
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 190
  Width = 189
  object pFIBDatabase1: TpFIBDatabase
    AutoReconnect = True
    SQLDialect = 1
    Timeout = 0
    WaitForRestoreConnect = 0
    Left = 32
    Top = 16
  end
  object pFIBDataSet1: TpFIBDataSet
    Left = 120
    Top = 72
  end
  object pFIBQuery1: TpFIBQuery
    Transaction = pFIBTransaction1
    Database = pFIBDatabase1
    Left = 32
    Top = 72
  end
  object pFIBTransaction1: TpFIBTransaction
    DefaultDatabase = pFIBDatabase1
    TimeoutAction = TACommit
    TRParams.Strings = (
      'write'
      'isc_tpb_nowait'
      'read_committed'
      'rec_version')
    TPBMode = tpbDefault
    Left = 120
    Top = 16
  end
  object OraSession1: TOraSession
    LoginPrompt = False
    Left = 32
    Top = 128
  end
  object OraQuery1: TOraQuery
    Left = 120
    Top = 128
  end
end
