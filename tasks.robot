*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             RPA.PDF
Library             OperatingSystem


*** Variables ***
${WEB_URL}          https://robotsparebinindustries.com/#/robot-order
${CSV_URL}          https://robotsparebinindustries.com/orders.csv

${imgs}             ${CURDIR}/temp/image_files
${pdfs}             ${CURDIR}/temp/pdf_files
${output}           ${CURDIR}/temp/output

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Log    Creating orders.
    [Setup]    Init Bot
    Open the Robot Order Website
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        Preview the robot
        Submit The Order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order Number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order Number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    //*[@id="order-another"]
    END
    Archive Folder With ZIP
    ...    folder=${pdfs}
    ...    archive_name=${CURDIR}/output/pdf_archive.zip
    ...    recursive=True
    ...    include=*.pdf

    [Teardown]    Close Browser


*** Keywords ***

Init Bot
    Empty Directory    ${imgs}
    Empty Directory    ${pdfs}
    Empty Directory    ${output}

    Create Directory    ${imgs}
    Create Directory    ${pdfs}

Open the Robot Order Website
    Log    openning website ${WEB_URL}
    Open Available Browser    ${WEB_URL}

Get Orders
    Log    downloading order.csv
    Download    url=${CSV_URL}    target_file=${CURDIR}/temp/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    path=${CURDIR}/temp/orders.csv
    RETURN    ${orders}

Close the annoying modal
    Log    close popup
    Wait And Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]

Fill the form
    [Arguments]    ${order}
    Log    filling the form
    Select From List By Value    //*[@id="head"]    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    //*[@id="address"]    ${order}[Address]

Preview the robot
    Log    previewing
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Log    submitting order
    Mute Run On Failure    Page Should Contain Element
    Click button    //*[@id="order"]
    Page Should Contain Element    //*[@id="receipt"]

Take a screenshot of the robot
    [Arguments]    ${order_num}
    Log    saving screenshot
    Set Local Variable    ${screenshot}    ${imgs}/${order_num}.png
    Sleep    1sec
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${screenshot}
    RETURN    ${screenshot}

Go to order another robot

Store the receipt as a PDF file
    [Arguments]    ${order_num}

    Wait Until Element Is Visible    //*[@id="receipt"]
    Log    printing pdf for ${order_num}
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML

    Set Local Variable    ${pdf_name}    ${pdfs}/${order_num}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${pdf_name}
    RETURN    ${pdf_name}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}

    Log    embedding screenshot in pdf
    Open PDF    ${pdf}
    @{file}=    Create List    ${screenshot}

    Add Files To PDF    ${file}    ${pdf}    ${True}

    Close PDF    ${pdf}


