*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP achieve of the receipts and the images.

Library        RPA.Browser.Selenium
Library        RPA.HTTP
Library        RPA.Tables
Library        RPA.PDF
Library        OperatingSystem
Library        RPA.Archive
Library        RPA.Dialogs
Library        RPA.Robocloud.Secrets

*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    cre
    Open Available Browser  ${url}[url]

Ask for user input
    Add text input    csv_link      CSV file link
    ${csv_link}=  Run dialog
    [Return]    ${csv_link.csv_link}

Download CSV file
    [Arguments]     ${csv_link}
    #https://robotsparebinindustries.com/orders.csv
    Download    ${csv_link}  overwrite=True

Get order
    @{orders}=  Read table from CSV    orders.csv   header=True
    [Return]    @{orders}

Close the annoying modal
    Wait And Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]     ${order}
    Select From List By Index    id:head  ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    //*[@type="number"]   ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Wait And Click Button    id:order

Resubmit the order
    ${check_id_visible}=    Is Element Visible    id:receipt
    IF    ${check_id_visible} == False
        Submit the order
    END
Store the order receipt as a PDF file
    [Arguments]     ${name}
    Resubmit the order
    Resubmit the order
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}      ${CURDIR}${/}output${/}receipts${/}${name}.pdf
    [Return]        ${CURDIR}${/}output${/}receipts${/}${name}.pdf

Take a screenshot of the robot
    [Arguments]     ${name}
    Wait Until Element Is Visible    id:robot-preview
    ${screenshot_path}=     Capture Element Screenshot    id:robot-preview    filename=${CURDIR}${/}output${/}receipts${/}${name}.png
    [Return]    ${screenshot_path}  

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot_path}   ${pdf_path}
    ${pdf}=     Open Pdf    ${pdf_path} 
    Add Watermark Image To Pdf    ${screenshot_path}    ${pdf_path}
    Close Pdf   ${pdf}
    Remove File     ${screenshot_path}

Order another robot
    Click Button    id:order-another

Create a ZIP file with the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${csv_link}=    Ask for user input
    Download CSV file   ${csv_link}
    
    @{orders}=  Get order

    FOR     ${order}   IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Submit the order
        Resubmit the order
        ${pdf_path}=    Store the order receipt as a PDF file   ${order}[Order number]
        Sleep    1s
        ${screenshot_path}=     Take a screenshot of the robot  ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot_path}    ${pdf_path}
        Order another robot
    END
    Create a ZIP file with the receipts

