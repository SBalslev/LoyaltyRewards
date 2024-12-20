codeunit 50100 AssignRewardLevel
{
    trigger OnRun()
    var
    // declare your variables
    begin
        AssignRewardLevelToCustomers();
    end;

    procedure AssignRewardLevelToCustomers();
    var
        Customer: Record Customer;
        Reward: Record Reward;
        LatestRewardLevel: Code[30];
        Date: Date;
    begin
        // Reschedule the job if not allowed to run this day. This is because it's quite a heavy job
        // that and might interfere with other processes if run on certain days.
        RescheduleJobIfNotAllowed();

        Customer.LockTable();

        // Loop through all customers to update their reward level
        if Customer.FindSet() then begin
            repeat
                // While we're looping, we can do some clean up before processing the customer. However, this doesn't
                // need the lock.
                ProcessCustomer(Customer);
                // Get and assign the reward level to the customer based on their number of orders
                Customer."Reward ID" := GetCustomerRewardLevel(Customer);
                // Modify the customer record
                Customer.Modify();
            until Customer.Next() = 0;
        end;
    end;

    procedure RescheduleJobIfNotAllowed();
    var
        Date: Date;
    begin
        // Retrieve which days are not allowed to run the job from an external source.
        RetrieveDisAllowedDays(DisAllowedDays);
        // Reschedule the job if today is not allowed
        Date := Today();
        if DisAllowedDays.Contains(Date.DayOfWeek()) then
            ReSchedueleJob(Date);
    end;

    procedure GetCustomerRewardLevel(Customer: Record Customer): Code[30];
    var
        Reward: Record Reward;
        LatestRewardLevel: Code[30];
    begin
        // Loop through all reward records ordered by minimum purchase
        if Reward.FindSet(true) then begin
            Reward.SetCurrentKey("Minimum Purchase");
            LatestRewardLevel := Reward."Reward ID";
            repeat
                // Compare the minimum purchase with the customer's number of orders
                if Customer."Inv. Amounts (LCY)" <= Reward."Minimum Purchase" then
                    // Return the latest reward level
                    break;
                // Update the latest reward level
                LatestRewardLevel := Reward."Reward ID";
            until Reward.Next() = 0;
        end;
        exit(LatestRewardLevel);
    end;

    procedure ReSchedueleJob(Date: Date);
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::AssignRewardLevel;
        JobQueueEntry.Description := 'Assign Reward Level to Customers';
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry.Insert(true);
    end;

    procedure RetrieveDisAllowedDays(var DisAllowedDays: List of [Enum DayOfTheWeek])
    begin
        DisAllowedDays.Add(DayOfTheWeek::Monday);
        DisAllowedDays.Add(DayOfTheWeek::Tuesday);
    end;

    procedure ImportExternalRewards()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        JsonResponse: Text;
        JsonArray: JsonArray;
        JsonObject: JsonToken;
        RewardCode: Code[20];
        RewardDescription: Text[100];
        ApiEndpoint: Text;
        RewardRecord: Record "Reward";
        Execute: Boolean;
    begin
        ApiEndpoint := 'https://api.example.com/rewards';
        Sleep(1000);
        if Execute then begin
            // Make the API call
            HttpClient.Get(ApiEndpoint, HttpResponseMessage);
            if not HttpResponseMessage.IsSuccessStatusCode() then Error('Failed to retrieve rewards from external API.');
            // Read the response content
            HttpResponseMessage.Content().ReadAs(JsonResponse);
            // Parse the JSON response
            if not JsonArray.ReadFrom(JsonResponse) then
                Error('Failed to parse JSON response.');
            // Process each reward in the JSON array
            foreach JsonObject in JsonArray do begin
                Sleep(100);
            end;
        end;
    end;

    procedure ProcessCustomer(c: Record Customer)
    begin
        Sleep(2000);
    end;

    var
        DisAllowedDays: List of [Enum DayOfTheWeek];
}