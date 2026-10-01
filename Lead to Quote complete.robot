*** Settings ***

Documentation     New test suite
Library           QForce
Library           String
Library           DateTime
Library           Collections
Suite Setup       Open Browser                ${loginURL}                 chrome
Suite Teardown    Close All Browsers
Resource          Data.resource

*** Keywords ***
Login salesforce
    TypeText                    Username                    ${username}
    ClickText                   Log in
    TypeText                    Password                    ${password}
    ClickText                   Log in
    TypeText                    Verification Code           ${passkey}
    ClickText                   Verify
    VerifyText                  Developer Edition

Lead Creation to Quote complete
    ${RandomSuffix}       Generate Random String      5                      [LETTERS][NUMBER]
    ${CurrentTime}        Get Current Date            result_format=%H:%M
    ${CloseDate}          Get Current Date            increment=7 days       result_format=%m/%d/%Y
    ${Num}                Get Current Date            increment=7 days       result_format=%m/%d/%Y
    ${DynamicName}        Catenate                    Garvansh               ${CurrentTime}
    ${DynamicLastName}    Catenate                    Garvansh               ${RandomSuffix}
    ${DynamicCompany}     Catenate                    Comp                   ${RandomSuffix}
    ${Quote_Num}          Catenate                    Quote                  ${Num}


    ClickText                   Leads
    ClickText                   New
    VerifyText                  Lead Information
    Clicktext                   Salutation                  Mr.
    ClickText                   Last Name
    TypeText                    Last Name                   ${DynamicName}
    ClickText                   Company
    TypeText                    Company                     ${DynamicCompany}
    Picklist                    Lead Status                 Open - Not Contacted
    ClickText                   Save                        partial_match=False
    ClickElement                xpath=//*[text()='Show more actions']
    ClickText                   Convert
    VerifyText                  Convert Lead
    VerifyPickList              Converted Status            Closed - Converted
    ClickText                   Convert
    VerifyText                  Your lead has been converted
    ClickText                   ${DynamicCompany}
    ClickText                   Details
    VerifyText                  ${DynamicCompany}
    ClickText                   Related
    VerifyText                  ${DynamicName}
    ClickText                   ${DynamicName}
    Clicktext                   Details
    VerifyText                  ${DynamicCompany}
    ClickText                   Related
    ClickElement                xpath=//article[contains(@aria-label,'Opportunities')]//a[.//span[contains(text(),'View All')]]
    ClickText                   ${DynamicCompany}
    ClickText                   Details
    ClickElement                xpath\=//a[contains(@href, 'OpportunityLineItems')]
    ClickElement                xpath=//div[@title='Add Products']

# ===================================Products adding and verification=======================

    # @{Product_list2}             Create List                 GenWatt Diesel 1000kW       Installation: Industrial - High                SLA: Gold
    # @{Quantity_List2}            Create List                 1                           2                           3

    &{Product_Price}            Create Dictionary
    @{Product_list}             Create List                 GenWatt Diesel 1000kW
    @{Quantity_List}            Create List                 1

    ClickElement                xpath=//input[@aria-describedby='Search']
    FOR                         ${Product}                  IN                          @{Product_list}
        TypeText                Search Products             ${Product}
        ClickElement            xpath=//lightning-icon[@icon-name='utility:search']
        ClickElement            xpath=//div[@role='listbox']
        ClickCheckbox           ${Product}                  on
    END

    ClickElement                xpath=//button[@title='Next']
    FOR                         ${Index}                    ${Product}                  IN ENUMERATE         @{Product_list}
        ClickElement            xpath=//tr[.//a[text()='${Product}']]//button[contains(@title,'Edit Quantity')]                 clicks=2
        VerifyElement           xpath=//tr[.//a[text()='${Product}']]//input

        TypeText                Quantity                    ${Quantity_List}[${Index}]                       anchor=${Product}
        LogScreenshot


    END
    # ----------------------------------Multiple products quantity adding----------------------------------------

    # FOR                         ${index}                    ${Product}                  IN ENUMERATE                @{Product_list2}
    #     ClickElement            xpath=//tr[.//a[text()='${Product}']]//button[contains(@title,'Edit Quantity')]     clicks=2
    #     
    #     TypeText                Quantity                    ${Quantity_List2}[${index}]                              anchor=${Product}
    #     
    # END
    # ---------------------------------------------------------------------------------------------------------------------
    ClickText                   Save
    ClickElement                xpath\=//a[text()\='${DynamicCompany}']
    ClickText                   Details

    ClickText                   Products                    partial_match=False

    &{product_price}            Create Dictionary
    &{product_quantity}         Create Dictionary

    FOR                         ${prod}                     IN                          @{Product_list}
        ${quantity}=            Get Text                    xpath\=//tr[.//a[text()\='${prod}']]//span[contains(@class,'uiOutputNumber')]
        ${sales_price}=         Get Text                    xpath\=//tr[.//a[text()\='${prod}']]//span[contains(@class,'forceOutputCurrency')]
        ${product_quantity}[${prod}]=                       Set Variable                ${quantity}
        ${product_price}[${prod}]=                          Set Variable                ${sales_price}
    END

    ${total_amount}=            Set Variable                0

    FOR                         ${produ}                    IN                          @{Product_list}
        ${quantity}=            Convert To Number           ${product_quantity}[${produ}]
        ${sales_price}=         Remove String               ${product_price}[${produ}]                       $                  ,
        ${sales_price}=         Convert To Number           ${sales_price}
        ${product_total}=       Evaluate                    ${quantity} * ${sales_price}
        ${total_amount}=        Evaluate                    ${total_amount} + ${product_total}
    END

    ClickElement                xpath=//a[contains(text(),'${DynamicCompany}')]
    ClickText                   Details
    ${opportunity_amount}=      Get Text                    xpath\=//sfa-output-opportunity-amount[@slot\='outputField']
    ${opportunity_amount}=      Remove String               ${opportunity_amount}       $                    ,
    ${opportunity_amount}=      Convert To Number           ${opportunity_amount}

    IF                          ${total_amount} == ${opportunity_amount}
        Log                     Product Total and Opportunity Amount are EQUAL: ${total_amount} : ${opportunity_amount}         console=True
    ELSE
        Log                     Product Total and Opportunity Amount are NOT EQUAL      console=True
    END
    
    # =====================================================Quote creation and Verification===========================

    ScrollTo                    xpath\=//span[@title\='Quotes']
    ClickElement                xpath\=//span[@title\='Quotes']
    ClickText                   New Quote
    TypeText                    Quote Name                        ${Quote_Num}
    ClickText                   Save                        partial_match=False
    CLickText                   ${Quote_Num}
    VerifyText                  ${Product}
    ClickText                   Details
    ${G_Total}                  GetText                     xpath\=//*[@data-target-selection-name\='sfdc:RecordField.Quote.GrandTotal']//lightning-formatted-text
    ${G_Total}                  Remove String               ${G_Total}                  $                    ,
    ${G_Total}                  Convert To Number           ${G_Total}
    
    IF                        ${G_Total} == ${total_amount}
        Log                   Grand Total and Opportunity Total Amount are Equal : ${G_Total} : ${total_amount}                 console=True
    ELSE
        Log                   Grand Total is not equal to Opportunity Total                        console=True
    END                    