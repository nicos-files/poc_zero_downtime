-- Crea DB si no existe
IF DB_ID('appdb') IS NULL
BEGIN
  EXEC('CREATE DATABASE appdb');
END
GO

USE appdb;
GO

-- Tablas (idempotente)
IF OBJECT_ID('dbo.customers') IS NULL
BEGIN
  CREATE TABLE dbo.customers(
    id INT IDENTITY PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(200) NOT NULL UNIQUE,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END

IF OBJECT_ID('dbo.orders') IS NULL
BEGIN
  CREATE TABLE dbo.orders(
    id INT IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES dbo.customers(id),
    total_amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
GO

IF OBJECT_ID('dbo.heartbeat') IS NULL
BEGIN
  CREATE TABLE dbo.heartbeat (
    id INT NOT NULL PRIMARY KEY,
    ts_utc DATETIME2(3) NOT NULL
  );

  -- Seed inicial para que Debezium tenga algo que snapshooter / trackear
  INSERT INTO dbo.heartbeat (id, ts_utc)
  VALUES (1, SYSUTCDATETIME());
END
GO

IF OBJECT_ID('dbo.UPDT_Basics') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDT_Basics](
    [Update Number]                INT NULL,
    [Development]                  BIT NULL,
    [Production]                   BIT NULL,
    [E/C For Prod]                 BIT NULL,
    [E/C For Deve]                 BIT NULL,
    [Insp Proc Change]             BIT NULL,
    [Elec Change]                  BIT NULL,
    [Kit Location Change]          BIT NULL,
    [Clerical]                     BIT NULL,
    [Reason For Rls]               VARCHAR(8000) NULL,
    [Test At Track]                BIT NULL,
    [Test On Dyno]                 BIT NULL,
    [Test On EAX Dyno]             BIT NULL,
    [Test Before]                  BIT NULL,
    [Use ASAP]                     BIT NULL,
    [No Test Rq'd]                 BIT NULL,
    [Tested At TRD]                BIT NULL,
    [Notify KW]                    BIT NULL,
    [Notify PLR]                   BIT NULL,
    [Will Test At TRD]             BIT NULL,
    [Will Test At EAX]             BIT NULL,
    [Will Test At Track]           BIT NULL,
    [E BOM / Parts List Instructions] VARCHAR(8000) NULL,
    [Production Instructions]      VARCHAR(8000) NULL,
    [Purchasing Instructions]      VARCHAR(8000) NULL,
    [Engineering Comments]         VARCHAR(8000) NULL,
    [Additional Comments]          VARCHAR(8000) NULL,
    [Build Shop Instructions]      VARCHAR(8000) NULL,
    [Updated IM Picture Included]  BIT NULL,
    [Updated IM Picture To Be Done] BIT NULL,
    [Updated IM Picture Not Rq'd]  BIT NULL,
    [Add To Lead Time Sheet]       BIT NULL,
    [Tabular Drawing]              BIT NULL,
    [Notify Track Support]         BIT NULL,
    [Title]                        NVARCHAR(50) NULL,
    [Engine Phase]                 NVARCHAR(50) NULL,
    [Released By:]                 NVARCHAR(50) NULL,
    [Revised By:]                  NVARCHAR(50) NULL,
    [Engineer]                     NVARCHAR(50) NULL,
    [Series]                       NVARCHAR(50) NULL,
    [Release Date]                 DATETIME NULL,
    [Released]                     BIT NULL,
    [Notify Engineering Cmplt]     BIT NULL,
    [Project Status]               NTEXT NULL,
    [KW Complete]                  BIT NULL,
    [PLR Complete]                 BIT NULL,
    [Production Approval]          NVARCHAR(4) NULL,
    [Engineering Approval]         NVARCHAR(4) NULL,
    [Manufacturing Approval]       NVARCHAR(4) NULL,
    [Production Approval Date]     DATETIME NULL,
    [Engineering Approval Date]    DATETIME NULL,
    [Manufacturing Approval Date]  DATETIME NULL,
    [RouteKW]                      BIT NULL,
    [RoutePLR]                     BIT NULL,
    [RoutePJ]                      BIT NULL,
    [RoutePS]                      BIT NULL,
    [Development Approval Date]    NVARCHAR(4) NULL,
    [PLR Distrubution]             BIT NULL,
    [Entered]                      BIT NULL,
    [Update Attachement]           BIT NULL,
    [RouteSW]                      BIT NULL,
    [Grouped With]                 INT NULL,
    [isSubmitted]                  BIT NULL,
    [User_ID]                      INT NULL,
    [Update_ID]                    INT IDENTITY(1,1) NOT NULL,
    [isReturned]                   BIT NULL,
    [Revised_Date]                 DATETIME NULL,
    [DLS]                          BIT NULL,
    [isCopy]                       BIT NULL,
    [CopyFrom_UpdateID]            INT NULL,
    [isERPAdmin]                   BIT NULL,
    [SysproProcessStart_DT]        DATETIME NULL,
    [SysproProcessEnd_DT]          DATETIME NULL,
    [isSysproInProcess]            BIT NULL,
    [isSysproComplete]             BIT NULL,
    [isJGRDist]                    BIT NULL,
    [isCreatedFromSpecChange]      BIT NULL,
    [SpecChange_ID]                INT NULL,
    [CreateDate]                   DATETIME NULL,
    CONSTRAINT PK_UPDT_Basics PRIMARY KEY CLUSTERED ([Update_ID] ASC)
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.UPDateSpecifics1') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDateSpecifics1](
    [Update_ID]                    INT NULL,
    [Update Number]                INT NULL,
    [#]                            INT NULL,
    [New Part Number]              NVARCHAR(50) NULL,
    [Description]                  NVARCHAR(60) NULL,
    [Description - Long]           NVARCHAR(30) NULL,
    [B/M]                          NVARCHAR(50) NULL,
    [CC]                           NVARCHAR(50) NULL,
    [LT]                           NVARCHAR(50) NULL,
    [SS]                           NVARCHAR(50) NULL,
    [EBQ]                          NVARCHAR(50) NULL,
    [DS]                           NVARCHAR(50) NULL,
    [Plnr]                         NVARCHAR(50) NULL,
    [Byr]                          NVARCHAR(50) NULL,
    [ABC Code]                     NVARCHAR(50) NULL,
    [Comm Code]                    NVARCHAR(50) NULL,
    [Pan]                          FLOAT NULL,
    [Old Part Number]              NVARCHAR(50) NULL,
    [Old Part Number CC]           NVARCHAR(50) NULL,
    [Status]                       NVARCHAR(50) NULL,
    [Order Qty]                    NVARCHAR(50) NULL,
    [Due Date]                     DATETIME NULL,
    [Vendor]                       NVARCHAR(50) NULL,
    [Vendor Part Number]           NVARCHAR(50) NULL,
    [Pg-Item Number]               NVARCHAR(50) NULL,
    [Insp Comments]                NVARCHAR(50) NULL,
    [Drwg Rq'd]                    NVARCHAR(225) NULL,
    [To Whom]                      NVARCHAR(50) NULL,
    [Qty]                          NVARCHAR(50) NULL,
    [NB]                           FLOAT NULL,
    [RB]                           FLOAT NULL,
    [Drawing Rcv'd]                BIT NULL,
    [DocControl_Complete]          BIT NULL,
    [Drawing N/A]                  BIT NULL,
    [Mass]                         FLOAT NULL,
    [S/N]                          NVARCHAR(1) NULL,
    [Structure On]                 DATETIME NULL,
    [Structure Off]                DATETIME NULL,
    [Required in LT Sheet]         BIT NULL,
    [Picture Change]               VARCHAR(50) NULL,
    [Engine Spec]                  VARCHAR(50) NULL,
    [NewPartAction]                VARCHAR(100) NULL,
    [NewPartActionNotes]           VARCHAR(150) NULL,
    [NewPartKitAction]             VARCHAR(150) NULL,
    [OldPartAction]                VARCHAR(100) NULL,
    [OldPartActionNotes]           VARCHAR(150) NULL,
    [OldPartKitAction]             VARCHAR(150) NULL,
    [isEBOM]                       BIT NULL,
    [Page]                         VARCHAR(20) NULL,
    [ItemNumber]                   INT NULL,
    [Specific_ID]                  INT IDENTITY(1,1) NOT NULL,
    [isDueDateEmail]               BIT NULL,
    [DLS]                          BIT NULL,
    [isCostFactorComplete]         BIT NULL,
    [isEnteredERP]                 BIT NULL,
    [NewCost]                      FLOAT NULL,
    [ObsoleteCost]                 FLOAT NULL,
    [SCP]                          BIT NULL,
    [SCP_WH]                       VARCHAR(50) NULL,
    [SCP_SS]                       FLOAT NULL,
    [SCP_Min]                      FLOAT NULL,
    [SCP_Max]                      FLOAT NULL,
    [SCP_Rule]                     VARCHAR(50) NULL,
    [isCopy]                       BIT NULL,
    [CopyFrom_SpecificID]          INT NULL,
    [isERP]                        BIT NULL,
    [isMPS]                        BIT NULL,
    [SSWH13]                       VARCHAR(10) NULL,
    [SSWH15]                       VARCHAR(10) NULL,
    [SSWH01]                       VARCHAR(10) NULL,
    [SysproSN]                     BIT NULL,
    [DueDateReminderSentDate]      DATETIME NULL,
    [Original#]                    INT NULL,
    [Reorder#]                     INT NULL,
    [Fix#]                         INT NULL,
    [isMileageTracked]             BIT NULL,
    [SysproSyncCompleteDate]       DATETIME NULL,
    CONSTRAINT PK_UPDateSpecifics1 PRIMARY KEY CLUSTERED ([Specific_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.USER_UpdateApprovers') IS NULL
BEGIN
  CREATE TABLE [dbo].[USER_UpdateApprovers](
    [Approver_ID]  INT IDENTITY(1,1) NOT NULL,
    [User_ID]      INT NULL,
    [Approval_Code] VARCHAR(50) NULL,
    [Routing_ID]   INT NULL,
    CONSTRAINT [PK_USER_UpdateApprovers] PRIMARY KEY CLUSTERED ([Approver_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.UPDT_JOIN_UpdatesRoutings') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDT_JOIN_UpdatesRoutings](
    [UpdateRouting_ID] INT IDENTITY(1,1) NOT NULL,
    [Update_ID]        INT NULL,
    [Routing_ID]       INT NULL,
    [Routing_Order]    INT NULL,
    CONSTRAINT [PK_UPDT_JOIN_UpdatesRoutings] PRIMARY KEY CLUSTERED ([UpdateRouting_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.UPDT_ReturnToAuthor') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDT_ReturnToAuthor](
    [Return_ID]     INT IDENTITY(1,1) NOT NULL,
    [Return_DT]     DATETIME NULL,
    [Update_ID]     INT NULL,
    [Return_Text]   VARCHAR(8000) NULL,
    [Return_UserID] INT NULL,
    [Log_ID]        INT NULL,
    CONSTRAINT PK_UPDT_ReturnToAuthor PRIMARY KEY CLUSTERED ([Return_ID] ASC)
  ) ON [PRIMARY];
END
GO

USE appdb;
GO

IF OBJECT_ID('dbo.BOM_Operations') IS NULL
BEGIN
  CREATE TABLE [dbo].[BOM_Operations](
    [Op_ID]        INT IDENTITY(1,1) NOT NULL,
    [OpType_ID]    INT NULL,
    [OpType_Name]  VARCHAR(100) NULL,
    [BOM_ID]       INT NULL,
    [WorkCenter]   VARCHAR(20) NULL,
    [SetUpTime]    FLOAT NULL,
    [StartUpTime]  FLOAT NULL,
    [StartUpQty]   FLOAT NULL,
    [FixedLT]      BIT NULL,
    [ElapsedTime]  FLOAT NULL,
    [Supplier]     VARCHAR(20) NULL,
    [LeadTime]     FLOAT NULL,
    [OffSiteTime]  FLOAT NULL,
    [QtyPer]       FLOAT NULL,
    [UOM]          VARCHAR(20) NULL,
    [UnitValue]    MONEY NULL,
    [Planner]      VARCHAR(10) NULL,
    [Buyer]        VARCHAR(10) NULL,
    [OrderBy]      INT NULL,
    [Route]        INT NULL,
    CONSTRAINT [PK_BOM_Operations] PRIMARY KEY CLUSTERED ([Op_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.BOM_ChildPartNumbers') IS NULL
BEGIN
  CREATE TABLE [dbo].[BOM_ChildPartNumbers](
    [CP_ID]          INT IDENTITY(1,1) NOT NULL,
    [BOM_ID]         INT NULL,
    [ChildPartNumber] VARCHAR(30) NULL,
    [Qty]            FLOAT NULL,
    [OrderBy]        INT NULL,
    [Route]          INT NULL,
    CONSTRAINT [PK_BOM_ChildPartNumbers] PRIMARY KEY CLUSTERED ([CP_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.BOM_Master') IS NULL
BEGIN
  CREATE TABLE [dbo].[BOM_Master](
    [BOM_ID]           INT IDENTITY(1,1) NOT NULL,
    [User_ID]          INT NULL,
    [Update_ID]        INT NULL,
    [LineItem_Number]  INT NULL,
    [Create_DT]        DATETIME NULL,
    [Modify_DT]        DATETIME NULL,
    [Modify_UserID]    INT NULL,
    [Planner]          VARCHAR(10) NULL,
    [isSysproComplete] BIT NULL,
    [SysproSync_DT]    DATETIME NULL,
    [tempChildPartNumber] VARCHAR(50) NULL,
    CONSTRAINT [PK_BOM_Master] PRIMARY KEY CLUSTERED ([BOM_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.BOM_OperationTypes') IS NULL
BEGIN
  CREATE TABLE [dbo].[BOM_OperationTypes](
    [OpType_ID]   INT IDENTITY(1,1) NOT NULL,
    [OpType_Name] VARCHAR(50) NULL,
    CONSTRAINT [PK_BOM_OperationTypes] PRIMARY KEY CLUSTERED ([OpType_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.UPDT_JOIN_UpdatesPageItems') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDT_JOIN_UpdatesPageItems](
    [PageItem_ID]     INT IDENTITY(1,1) NOT NULL,
    [Update_ID]       INT NULL,
    [LineItem_Number] INT NULL,
    [Specific_ID]     SMALLINT NULL,
    [Page_Number]     VARCHAR(50) NULL,
    [Item_Number]     INT NULL,
    [Engine Spec]     VARCHAR(50) NULL,
    [Qty]             FLOAT NULL,
    CONSTRAINT [PK_UPDT_JOIN_UpdatesPageItems] PRIMARY KEY CLUSTERED 
    (
      [PageItem_ID] ASC
    ) WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      IGNORE_DUP_KEY = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON,
      FILLFACTOR = 80
    ) ON [PRIMARY]
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.UPDT_JOIN_UpdatesKits') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDT_JOIN_UpdatesKits](
    [Join_ID]        INT IDENTITY(1,1) NOT NULL,
    [Update_ID]      INT NULL,
    [Specific_ID]    INT NULL,
    [LineItem_Number] INT NULL,
    [Kit_Name]       VARCHAR(50) NULL,
    [Kit_Action]     VARCHAR(50) NULL,
    [isNewPartAction] BIT NULL,
    [isOldPartAction] BIT NULL,
    [StructOn]       DATETIME NULL,
    [StructOff]      DATETIME NULL,
    [Qty]            FLOAT NULL,
    [EBOM_ID]        INT NULL,
    CONSTRAINT [PK_UPDT_JOIN_UpdatesKits] PRIMARY KEY CLUSTERED 
    (
      [Join_ID] ASC
    ) WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      IGNORE_DUP_KEY = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON,
      FILLFACTOR = 80
    ) ON [PRIMARY]
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.DATA_Kits') IS NULL
BEGIN
  CREATE TABLE [dbo].[DATA_Kits](
    [Kit_ID]     INT IDENTITY(1,1) NOT NULL,
    [Kit_Name]   VARCHAR(50) NULL,
    [Kit_Desc]   VARCHAR(100) NULL,
    [isDeleted]  BIT NULL,
    [Phase_Number] VARCHAR(50) NULL,
    [isBom]      BIT NULL,
    CONSTRAINT [PK_DATA_Kits] PRIMARY KEY CLUSTERED 
    (
      [Kit_ID] ASC
    ) WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      IGNORE_DUP_KEY = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON,
      FILLFACTOR = 80
    ) ON [PRIMARY]
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.EBOM_062104') IS NULL
BEGIN
  CREATE TABLE [dbo].[EBOM_062104](
    [Update_ID]          INT NULL,
    [Specific_ID]        INT NULL,
    [LineItem_Number]    INT NULL,
    [isNewPart]          BIT NULL,
    [Engine Spec]        VARCHAR(50) NULL,
    [Action]             VARCHAR(150) NULL,
    [Page]               VARCHAR(20) NULL,
    [ItemNumber]         INT NULL,
    [Page-Item]          VARCHAR(50) NULL,
    [Current Part Number] VARCHAR(50) NULL,
    [DESCRIPTION]        VARCHAR(150) NULL,
    [LONG_DESC]          VARCHAR(150) NULL,
    [Qty]                VARCHAR(50) NULL,
    [New Qty w/Action]   VARCHAR(50) NULL,
    [Old Part No]        VARCHAR(50) NULL,
    [Action Notes]       VARCHAR(150) NULL,
    [NewPartKitAction]   VARCHAR(150) NULL,
    [OldPartKitAction]   VARCHAR(150) NULL,
    [Kit_Name]           VARCHAR(50) NULL,
    [Picture Change]     VARCHAR(50) NULL,
    [Entered By]         VARCHAR(50) NULL,
    [Structure On]       DATETIME NULL,
    [Structure Off]      DATETIME NULL,
    [isEnteredERP]       BIT NULL,
    [Date Added]         DATETIME NULL,
    [isImportedData]     BIT NULL,
    [Coordinate_ID]      INT NULL,
    [isManualEntry]      BIT NULL,
    [isPLMActioned]      BIT NULL,
    [User_ID]            INT NULL,
    [EBOM_ID]            INT IDENTITY(1,1) NOT NULL,
    [Kit_Name_Old]       VARCHAR(50) NULL,
    [RevisedBy]          VARCHAR(100) NULL,
    [isCopied]           BIT NULL,
    [isPictureChanged]   BIT NULL,
    [isStructOnAndOff]   BIT NULL,
    [isOmitObsCCValidation] BIT NULL,
    [OmitCCValidation_UserID] INT NULL,
    [OmitCCValidation_DT] DATETIME NULL,
    [SpecChangeRevision] VARCHAR(20) NULL,
    [SpecChange_ID]      INT NULL,
    [isBomSyncComplete]  BIT NULL,
    [isBomSyncInProcess] BIT NULL,
    [BomSyncStartDT]     DATETIME NULL,
    [CopyFromEngineSpec] VARCHAR(30) NULL,
    [CompareColumn]      VARCHAR(300) NULL,
    CONSTRAINT [PK_EBOM_062104] PRIMARY KEY CLUSTERED ([EBOM_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.LOG_EBOMHistory') IS NULL
BEGIN
  CREATE TABLE [dbo].[LOG_EBOMHistory](
    [Log_ID]             INT IDENTITY(1,1) NOT NULL,
    [Log_DT]             DATETIME NULL,
    [EBOM_ID]            INT NULL,
    [Update_ID]          INT NULL,
    [Specific_ID]        INT NULL,
    [LineItem_Number]    INT NULL,
    [isNewPart]          BIT NULL,
    [Engine Spec]        VARCHAR(50) NULL,
    [Action]             VARCHAR(150) NULL,
    [Page]               VARCHAR(20) NULL,
    [ItemNumber]         INT NULL,
    [Page-Item]          VARCHAR(50) NULL,
    [Current Part Number] VARCHAR(50) NULL,
    [DESCRIPTION]        VARCHAR(150) NULL,
    [LONG_DESC]          VARCHAR(150) NULL,
    [Qty]                VARCHAR(50) NULL,
    [New Qty w/Action]   VARCHAR(50) NULL,
    [Old Part No]        VARCHAR(50) NULL,
    [Action Notes]       VARCHAR(150) NULL,
    [NewPartKitAction]   VARCHAR(150) NULL,
    [OldPartKitAction]   VARCHAR(150) NULL,
    [Kit_Name]           VARCHAR(50) NULL,
    [Picture Change]     VARCHAR(50) NULL,
    [Entered By]         VARCHAR(50) NULL,
    [Structure On]       DATETIME NULL,
    [Structure Off]      DATETIME NULL,
    [isEnteredERP]       BIT NULL,
    [Date Added]         DATETIME NULL,
    [isImportedData]     BIT NULL,
    [Coordinate_ID]      INT NULL,
    [isManualEntry]      BIT NULL,
    [User_ID]            INT NULL,
    [isPLMAction]        BIT NULL,
    [isRestoredRow]      BIT NULL,
    [isPLMConfirmAction] BIT NULL,
    [isDeletedFromEBOM]  BIT NULL,
    [isManualUpdate]     BIT NULL,
    [RevisedBy]          VARCHAR(100) NULL,
    [releaseUpdate_ID]   INT NULL,
    [releaseLineItem_Number] INT NULL,
    [isCopied]           BIT NULL,
    [ObsCC]              VARCHAR(10) NULL,
    [SpecChange_ID]      INT NULL,
    [CopyFromEngineSpec] VARCHAR(30) NULL,
    CONSTRAINT [PK_LOG_EBOMHistory] PRIMARY KEY CLUSTERED ([Log_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.UPDT_JOIN_UpdatesEBOM') IS NULL
BEGIN
  CREATE TABLE [dbo].[UPDT_JOIN_UpdatesEBOM](
    [EBOM_ID]         INT NULL,
    [Update_ID]       INT NULL,
    [Specific_ID]     INT NULL,
    [isNewPartAction] BIT NULL,
    [isOldPartAction] BIT NULL,
    [LineItem_Number] INT NULL,
    [Join_ID]         INT IDENTITY(1,1) NOT NULL,
    [ObsCC]           VARCHAR(10) NULL,
    CONSTRAINT [PK_UPDT_JOIN_UpdatesEBOM] PRIMARY KEY CLUSTERED ([Join_ID] ASC)
  ) ON [PRIMARY];
END
GO

IF OBJECT_ID('dbo.USER_Master') IS NULL
BEGIN
  CREATE TABLE [dbo].[USER_Master](
    [User_ID]                  INT IDENTITY(1,1) NOT NULL,
    [User_Login]               VARCHAR(50) NULL,
    [User_PasswordOld]         VARCHAR(50) NULL,
    [User_Password]            BINARY(16) NULL,
    [User_FirstName]           VARCHAR(50) NULL,
    [User_LastName]            VARCHAR(50) NULL,
    [User_Email]               VARCHAR(150) NULL,
    [Created_DT]               DATETIME NULL,
    [Created_By]               INT NULL,
    [isDeleted]                BIT NULL,
    [isOnHold]                 BIT NULL,
    [encUserID]                INT NULL,
    [isCoder]                  SMALLINT NULL,
    [isAdmin]                  SMALLINT NULL,
    [RowsPerPage]              INT NULL,
    [isAllSpecs]               BIT NULL,
    [GraphHeight]              INT NULL,
    [GraphWidth]               INT NULL,
    [Approval_Code]            VARCHAR(50) NULL,
    [Active_OrderID]           INT NULL,
    [isSuperUser]              BIT NULL,
    [isIpadUser]               BIT NULL,
    [IpadUserDate]             DATETIME NULL,
    [IpadUser_SetByUserID]     INT NULL,
    [isExternalUser]           BIT NULL,
    [isVendor]                 BIT NULL,
    [Supplier]                 VARCHAR(20) NULL,
    [SupplierFullName]         VARCHAR(100) NULL,
    [SpringsSummarySelectedYear] INT NULL,
    [ENshowAllPageSize]        INT NULL,
    [NewUserEmail]             VARCHAR(100) NULL,
    [OldEmail]                 VARCHAR(100) NULL,
    [isGeneralLogin]           BIT NULL,
    [ToolingPageSize]          INT NULL,
    CONSTRAINT [PK_USER_Master] PRIMARY KEY CLUSTERED 
    (
      [User_ID] ASC
    ) WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      IGNORE_DUP_KEY = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON,
      FILLFACTOR = 80
    ) ON [PRIMARY]
  ) ON [PRIMARY];
END
GO



-- Habilitar CDC a nivel DB
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name='appdb' AND is_cdc_enabled=1)
BEGIN
  EXEC sys.sp_cdc_enable_db;
END
GO

-- Habilitar CDC por tabla (idempotente)
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.customers'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'customers',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.orders'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'orders',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.heartbeat'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'heartbeat',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDT_Basics'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDT_Basics',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDateSpecifics1'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDateSpecifics1',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.USER_UpdateApprovers'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'USER_UpdateApprovers',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDT_JOIN_UpdatesRoutings'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDT_JOIN_UpdatesRoutings',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDT_ReturnToAuthor'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDT_ReturnToAuthor',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO

-- Habilitar CDC para tablas BOM / EBOM / USER que se migran
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.BOM_Operations'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'BOM_Operations',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.BOM_ChildPartNumbers'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'BOM_ChildPartNumbers',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.BOM_Master'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'BOM_Master',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.BOM_OperationTypes'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'BOM_OperationTypes',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDT_JOIN_UpdatesPageItems'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDT_JOIN_UpdatesPageItems',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDT_JOIN_UpdatesKits'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDT_JOIN_UpdatesKits',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.DATA_Kits'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'DATA_Kits',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.EBOM_062104'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'EBOM_062104',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.LOG_EBOMHistory'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'LOG_EBOMHistory',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.UPDT_JOIN_UpdatesEBOM'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'UPDT_JOIN_UpdatesEBOM',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.USER_Master'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'USER_Master',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO


-- (Opcional) Asegurar jobs CDC; si ya corren, puede loguear "already running" (benigno)
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobactivity sja ON sj.job_id = sja.job_id
    WHERE sj.name = 'cdc.appdb_capture'
      AND sja.stop_execution_date IS NULL
)
BEGIN
    EXEC sys.sp_cdc_start_job @job_type='capture';
END;

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobactivity sja ON sj.job_id = sja.job_id
    WHERE sj.name = 'cdc.appdb_cleanup'
      AND sja.stop_execution_date IS NULL
)
BEGIN
    EXEC sys.sp_cdc_start_job @job_type='cleanup';
END;

GO

-- SEED *solo si* está vacío (dispara snapshot o CDC y fuerza creación de tópicos)
IF NOT EXISTS (SELECT 1 FROM dbo.customers)
BEGIN
  INSERT INTO dbo.customers(name,email) VALUES ('Ada','ada@ex.com'),('Linus','linus@ex.com');
  INSERT INTO dbo.orders(customer_id,total_amount) VALUES (1,100.00),(2,230.50);
END
GO

-- SEED BOM / EBOM / USER *solo si* están vacías (útil para pruebas / snapshot)
IF NOT EXISTS (SELECT 1 FROM dbo.USER_Master)
BEGIN
  INSERT INTO dbo.USER_Master(
      User_Login, User_FirstName, User_LastName, User_Email, Created_DT, isDeleted
  )
  VALUES
      ('admin', 'System', 'Admin', 'admin@example.com', SYSUTCDATETIME(), 0),
      ('jdoe', 'John', 'Doe', 'jdoe@example.com', SYSUTCDATETIME(), 0);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.BOM_Master)
BEGIN
  INSERT INTO dbo.BOM_Master(
      User_ID, Update_ID, LineItem_Number, Create_DT, Planner, isSysproComplete
  )
  VALUES
      (1, 1001, 1, SYSUTCDATETIME(), 'PLN', 0);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.BOM_OperationTypes)
BEGIN
  INSERT INTO dbo.BOM_OperationTypes(OpType_Name)
  VALUES ('Assembly'), ('Welding'), ('Painting');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.BOM_Operations)
BEGIN
  INSERT INTO dbo.BOM_Operations(
      OpType_ID, OpType_Name, BOM_ID, WorkCenter, SetUpTime, StartUpTime,
      StartUpQty, FixedLT, ElapsedTime, QtyPer, UOM, UnitValue, Planner, Buyer, OrderBy, Route
  )
  VALUES
      (1, 'Assembly', 1, 'WC01', 1.0, 0.5, 10, 0, 2.0, 1.0, 'HR', 50.00, 'PLN', 'BUY', 1, 10);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.BOM_ChildPartNumbers)
BEGIN
  INSERT INTO dbo.BOM_ChildPartNumbers(
      BOM_ID, ChildPartNumber, Qty, OrderBy, Route
  )
  VALUES
      (1, 'CP-0001', 2.0, 1, 10),
      (1, 'CP-0002', 4.0, 2, 10);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DATA_Kits)
BEGIN
  INSERT INTO dbo.DATA_Kits(
      Kit_Name, Kit_Desc, isDeleted, Phase_Number, isBom
  )
  VALUES
      ('KIT-001', 'Test Kit', 0, 'PH1', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.EBOM_062104)
BEGIN
  INSERT INTO dbo.EBOM_062104(
      Update_ID, Specific_ID, LineItem_Number, isNewPart, [Engine Spec],
      [Action], [Page], ItemNumber, [Page-Item], [Current Part Number],
      [DESCRIPTION], [LONG_DESC], [Qty], [New Qty w/Action],
      [Old Part No], [Action Notes], [Kit_Name], [Date Added],
      [isEnteredERP], [isImportedData], [isManualEntry], [User_ID]
  )
  VALUES
      (1001, 1, 1, 1, 'ENG-01',
       'ADD', '1', 10, '1-10', 'PART-0001',
       'Test Part', 'Test Part Long', '2', '2',
       NULL, 'Initial load', 'KIT-001', SYSUTCDATETIME(),
       0, 0, 1, 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.LOG_EBOMHistory)
BEGIN
  INSERT INTO dbo.LOG_EBOMHistory(
      Log_DT, EBOM_ID, Update_ID, Specific_ID, LineItem_Number,
      isNewPart, [Engine Spec], [Action], [Page], ItemNumber,
      [Page-Item], [Current Part Number], [DESCRIPTION], [LONG_DESC],
      [Qty], [New Qty w/Action], [Old Part No], [Action Notes],
      [Kit_Name], [Date Added], [isImportedData], [User_ID]
  )
  SELECT
      SYSUTCDATETIME(), EBOM_ID, Update_ID, Specific_ID, LineItem_Number,
      isNewPart, [Engine Spec], [Action], [Page], ItemNumber,
      [Page-Item], [Current Part Number], [DESCRIPTION], [LONG_DESC],
      [Qty], [New Qty w/Action], [Old Part No], [Action Notes],
      [Kit_Name], [Date Added], [isImportedData], [User_ID]
  FROM dbo.EBOM_062104
  WHERE NOT EXISTS (SELECT 1 FROM dbo.LOG_EBOMHistory);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.UPDT_JOIN_UpdatesEBOM)
BEGIN
  INSERT INTO dbo.UPDT_JOIN_UpdatesEBOM(
      EBOM_ID, Update_ID, Specific_ID, isNewPartAction, isOldPartAction,
      LineItem_Number, ObsCC
  )
  SELECT TOP 1
      EBOM_ID, Update_ID, Specific_ID, 1, 0, LineItem_Number, NULL
  FROM dbo.EBOM_062104;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.UPDT_JOIN_UpdatesPageItems)
BEGIN
  INSERT INTO dbo.UPDT_JOIN_UpdatesPageItems(
      Update_ID, LineItem_Number, Specific_ID, Page_Number, Item_Number, [Engine Spec], Qty
  )
  VALUES
      (1001, 1, 1, '1', 10, 'ENG-01', 2.0);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.UPDT_JOIN_UpdatesKits)
BEGIN
  INSERT INTO dbo.UPDT_JOIN_UpdatesKits(
      Update_ID, Specific_ID, LineItem_Number, Kit_Name, Kit_Action,
      isNewPartAction, isOldPartAction, StructOn, Qty
  )
  VALUES
      (1001, 1, 1, 'KIT-001', 'ADD', 1, 0, SYSUTCDATETIME(), 2.0);
END
GO

----------------------------------------------------------------
-- SEED TABLAS UPDT_* / USER_UpdateApprovers / Routings / Return
----------------------------------------------------------------

-- UPDT_Basics: crear el Update_ID = 1001 para matchear el resto
IF NOT EXISTS (SELECT 1 FROM dbo.UPDT_Basics WHERE [Update_ID] = 1001)
BEGIN
    SET IDENTITY_INSERT dbo.UPDT_Basics ON;

    INSERT INTO dbo.UPDT_Basics (
        [Update Number],
        [Development],
        [Production],
        [Reason For Rls],
        [Title],
        [Engine Phase],
        [Engineer],
        [Series],
        [Release Date],
        [Released],
        [isSubmitted],
        [User_ID],
        [Update_ID],
        [CreateDate]
    )
    VALUES (
        1001,                               -- Update Number
        1,                                  -- Development
        0,                                  -- Production
        'Initial test update for CDC / Debezium demo', -- Reason For Rls
        'Test Update 1001',                 -- Title
        'Phase-ENG',                        -- Engine Phase
        'Engineer 1',                       -- Engineer
        'Series-A',                         -- Series
        SYSUTCDATETIME(),                   -- Release Date
        1,                                  -- Released
        1,                                  -- isSubmitted
        1,                                  -- User_ID (admin)
        1001,                               -- Update_ID (for PoC)
        SYSUTCDATETIME()                    -- CreateDate
    );

    SET IDENTITY_INSERT dbo.UPDT_Basics OFF;
END
GO

-- UPDateSpecifics1: Specific_ID = 1 y Update_ID = 1001 (coherente con lo demás)
IF NOT EXISTS (SELECT 1 FROM dbo.UPDateSpecifics1)
BEGIN
    SET IDENTITY_INSERT dbo.UPDateSpecifics1 ON;

    INSERT INTO dbo.UPDateSpecifics1 (
        [Update_ID],
        [Update Number],
        [#],
        [New Part Number],
        [Description],
        [Description - Long],
        [B/M],
        [CC],
        [LT],
        [SS],
        [EBQ],
        [DS],
        [Plnr],
        [Byr],
        [ABC Code],
        [Comm Code],
        [Pan],
        [Old Part Number],
        [Old Part Number CC],
        [Status],
        [Order Qty],
        [Due Date],
        [Vendor],
        [Vendor Part Number],
        [Pg-Item Number],
        [Insp Comments],
        [Drwg Rq'd],
        [To Whom],
        [Qty],
        [NB],
        [RB],
        [Drawing Rcv'd],
        [DocControl_Complete],
        [Drawing N/A],
        [Mass],
        [S/N],
        [Structure On],
        [Structure Off],
        [Required in LT Sheet],
        [Picture Change],
        [Engine Spec],
        [NewPartAction],
        [NewPartActionNotes],
        [NewPartKitAction],
        [OldPartAction],
        [OldPartActionNotes],
        [OldPartKitAction],
        [isEBOM],
        [Page],
        [ItemNumber],
        [Specific_ID],
        [isDueDateEmail],
        [DLS],
        [isCostFactorComplete],
        [isEnteredERP],
        [NewCost],
        [ObsoleteCost],
        [SCP],
        [SCP_WH],
        [SCP_SS],
        [SCP_Min],
        [SCP_Max],
        [SCP_Rule],
        [isCopy],
        [CopyFrom_SpecificID],
        [isERP],
        [isMPS],
        [SSWH13],
        [SSWH15],
        [SSWH01],
        [SysproSN],
        [DueDateReminderSentDate],
        [Original#],
        [Reorder#],
        [Fix#],
        [isMileageTracked],
        [SysproSyncCompleteDate]
    )
    VALUES (
        1001,            -- Update_ID
        1001,            -- Update Number
        1,               -- #
        'PART-0001',     -- New Part Number
        'Test Part',     -- Description
        'Test Part Long',-- Description - Long
        NULL,NULL,NULL,NULL,NULL,NULL,
        'PLN',           -- Plnr
        'BUY',           -- Byr
        NULL,NULL,
        0,               -- Pan
        NULL,NULL,
        'ACTIVE',        -- Status
        '2',             -- Order Qty
        SYSUTCDATETIME(),-- Due Date
        'VENDOR1',       -- Vendor
        'VEND-PN-001',   -- Vendor Part Number
        '10',            -- Pg-Item Number
        'Initial inspection', -- Insp Comments
        NULL,            -- Drwg Rq'd
        'QA',            -- To Whom
        '2',             -- Qty
        0,0,             -- NB, RB
        0,0,0,           -- Drawing Rcv'd, DocControl_Complete, Drawing N/A
        1.0,             -- Mass
        NULL,            -- S/N
        SYSUTCDATETIME(),-- Structure On
        NULL,            -- Structure Off
        0,               -- Required in LT Sheet
        'N',             -- Picture Change
        'ENG-01',        -- Engine Spec
        'ADD',           -- NewPartAction
        'Initial add',   -- NewPartActionNotes
        'Add to KIT-001',-- NewPartKitAction
        NULL,NULL,NULL,  -- OldPart*
        1,               -- isEBOM
        '1',             -- Page
        10,              -- ItemNumber
        1,               -- Specific_ID (IDENTITY)
        0,               -- isDueDateEmail
        0,               -- DLS
        0,               -- isCostFactorComplete
        0,               -- isEnteredERP
        0,               -- NewCost
        0,               -- ObsoleteCost
        0,               -- SCP
        NULL,NULL,NULL,NULL,NULL,
        0,               -- isCopy
        NULL,            -- CopyFrom_SpecificID
        0,               -- isERP
        0,               -- isMPS
        NULL,NULL,NULL,  -- SSWH*
        0,               -- SysproSN
        NULL,            -- DueDateReminderSentDate
        NULL,NULL,NULL,  -- Original#, Reorder#, Fix#
        0,               -- isMileageTracked
        NULL             -- SysproSyncCompleteDate
    );

    SET IDENTITY_INSERT dbo.UPDateSpecifics1 OFF;
END
GO

-- USER_UpdateApprovers: vincular el admin (User_ID=1) con un routing
IF NOT EXISTS (SELECT 1 FROM dbo.USER_UpdateApprovers)
BEGIN
    INSERT INTO dbo.USER_UpdateApprovers (User_ID, Approval_Code, Routing_ID)
    VALUES
        (1, 'ENG', 1),
        (1, 'MFG', 2);
END
GO

-- UPDT_JOIN_UpdatesRoutings: ruta simple para el Update_ID 1001
IF NOT EXISTS (SELECT 1 FROM dbo.UPDT_JOIN_UpdatesRoutings)
BEGIN
    INSERT INTO dbo.UPDT_JOIN_UpdatesRoutings (Update_ID, Routing_ID, Routing_Order)
    VALUES
        (1001, 1, 1),
        (1001, 2, 2);
END
GO

-- UPDT_ReturnToAuthor: una devolución dummy asociada al Update 1001
IF NOT EXISTS (SELECT 1 FROM dbo.UPDT_ReturnToAuthor)
BEGIN
    INSERT INTO dbo.UPDT_ReturnToAuthor (
        Return_DT,
        Update_ID,
        Return_Text,
        Return_UserID,
        Log_ID
    )
    VALUES (
        SYSUTCDATETIME(),
        1001,
        'Initial return comment for testing CDC/Debezium.',
        1,        -- admin user
        NULL
    );
END
GO
