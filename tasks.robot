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
${WEB_URL}      https://robotsparebinindustries.com/#/robot-order
${CSV_URL}      https://robotsparebinindustries.com/orders.csv

${imgs}         ${CURDIR}/output/images
${pdfs}         ${CURDIR}/output/pdfs
${output}       ${CURDIR}/output


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    [Setup]    Init Bot
    Log    Creating orders.
    Open the Robot Order Website
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Wait Until Keyword Succeeds     4x     3s    Preview the robot
        Wait Until Keyword Succeeds     4x     3s    Submit The Order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    alias:btn_orderanother
    END
    Archive Folder With ZIP
    ...    folder=${pdfs}
    ...    archive_name=${CURDIR}/output/pdf_archive.zip
    ...    recursive=True
    ...    include=*.pdf

    [Teardown]    Close Browser


*** Keywords ***
Init Bot
    Create Directory    ${imgs}
    Create Directory    ${pdfs}

    Empty Directory    ${imgs}
    Empty Directory    ${pdfs}
    Empty Directory    ${output}

Open the Robot Order Website
    Log    openning website ${WEB_URL}
    Open Available Browser    ${WEB_URL}

Get Orders
    Log    downloading order.csv
    Download    url=${CSV_URL}    target_file=${CURDIR}/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    path=${CURDIR}/orders.csv
    RETURN    ${orders}

Close the annoying modal
    Log    close popup
    Wait And Click Button    alias:btn_yep

Fill the form
    [Arguments]    ${order}
    Log    filling the form
    Select From List By Value    alias:dd_head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    alias:in_legs    ${order}[Legs]
    Input Text    alias:in_address    ${order}[Address]

Preview the robot
    Log    previewing
    Click Button When Visible    alias:btn_preview
    Wait Until Element Is Visible    alias:img_preview

Submit the order
    Log    submitting order
    RPA.RobotLogListener.Mute Run On Failure    Page Should Contain Element
    Click Button    alias:btn_order
    Page Should Contain Element    alias:img_receipt

Take a screenshot of the robot
    [Arguments]    ${order_num}
    Log    saving screenshot
    Wait Until Element Is Visible   alias:img_preview
    Set Local Variable    ${screenshot}    ${imgs}/${order_num}.png
    Sleep    1sec
    Capture Element Screenshot    alias:img_preview    ${screenshot}
    RETURN    ${screenshot}

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    Log    printing pdf for ${order_num}
    ${order_receipt_html}=    Get Element Attribute    alias:img_receipt    attribute=outerHTML

    Set Local Variable    ${pdf_name}    ${pdfs}/${order_num}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${pdf_name}
    RETURN    ${pdf_name}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}

    Log    embedding screenshot in pdf
    Open PDF    ${pdf}
    @{file}=    Create List    ${screenshot}

    Add Files To PDF    ${file}    ${pdf}    ${True}
