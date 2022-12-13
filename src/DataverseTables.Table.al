table 70100 "Dataverse Table"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Mapping Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Mapping Name';
        }
        field(2; "BC Table"; integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = CONST(Table), "Object Subtype" = CONST('Normal'));
            Caption = 'BC Table';
        }
        field(3; "BC Table Caption"; Text[100])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Name" WHERE("Object ID" = FIELD("BC Table")));
            Caption = 'BC Table Caption';
            FieldClass = FlowField;
        }
        field(4; "Dataverse Table"; integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = CONST(Table), "Object Subtype" = CONST('CRM'));
            Caption = 'Dataverse Table';
        }
        field(5; "Dataverse Table Caption"; Text[100])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Name" WHERE("Object ID" = FIELD("Dataverse Table")));
            Caption = 'Dataverse Table Caption';
            FieldClass = FlowField;
        }
        field(6; "Dataverse UID"; integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = Field."No." where(TableNo = field("Dataverse table"));
            Caption = 'Dataverse UID';
        }
        field(7; "Dataverse UID Caption"; Text[100])
        {
            CalcFormula = Lookup(Field."Field Caption" WHERE(TableNo = FIELD("Dataverse Table"),
                                                              "No." = FIELD("Dataverse UID")));
            Caption = 'Dataverse UID Caption';
            FieldClass = FlowField;
        }
        field(8; "Modified Field"; integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = Field."No." where(TableNo = field("Dataverse table"));
            Caption = 'Modified Field';
        }
        field(9; "Modified Field Caption"; Text[100])
        {
            CalcFormula = Lookup(Field."Field Caption" WHERE(TableNo = FIELD("Dataverse Table"),
                                                              "No." = FIELD("Modified Field")));
            Caption = 'Modified Field Caption';
            FieldClass = FlowField;
        }
        field(10; "Sync Only Coupled Records"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sync Only Coupled Records';
        }
        field(11; "Table Name Dataverse"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Table Name Dataverse';
        }
        field(12; "Sync Direction"; Enum "Sync Direction")
        {
            DataClassification = ToBeClassified;
            Caption = 'Sync Direction';
        }
    }

    keys
    {
        key(Key1; "Mapping Name")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        DataverseField: Record "Dataverse Field";
    begin
        DataverseField.Reset;
        DataverseField.SetRange("Mapping Name", "Mapping Name");
        DataverseField.DeleteAll();
    end;

    procedure CreateJobQueueEntry(var IntegrationTableMapping: Record "Integration Table Mapping"; JobCodeunitId: Integer; JobDescription: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartTime: DateTime;
        JobQueueCategoryLbl: Label 'BCI INTEG', Locked = true;
    begin
        StartTime := CurrentDateTime() + 1000;
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", JobCodeunitId);
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.SetFilter("Earliest Start Date/Time", '<=%1', StartTime);
        if not JobQueueEntry.IsEmpty() then begin
            JobQueueEntry.DeleteTasks();
            Commit();
        end;

        JobQueueEntry.Init();
        Clear(JobQueueEntry.ID); // "Job Queue - Enqueue" is to define new ID
        JobQueueEntry."Earliest Start Date/Time" := StartTime;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := JobCodeunitId;
        JobQueueEntry."Record ID to Process" := IntegrationTableMapping.RecordId();
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry."Notify On Success" := false;
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryLbl;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueEntry."No. of Minutes between Runs" := 30;
        JobQueueEntry.Description := CopyStr(JobDescription, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Inactivity Timeout Period" := 720;
        JobQueueEntry.Insert(true);
    end;
}