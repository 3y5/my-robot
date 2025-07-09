*** Settings ***
Library           RPA.Browser.Playwright
Library           RPA.FileSystem
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Dialogs

Suite Setup       Open Browser Headless
Suite Teardown    Close Browser

*** Variables ***
${URL}            https://www.brembo.com/it
${CSV_OUT}        ${OUTPUT_DIR}/contacts.csv
${PDF_OUT}        ${OUTPUT_DIR}/contacts.pdf

*** Tasks ***
Scrape contacts for every query
    [Documentation]    Estrae i contatti dalla pagina web
    Create File  ${CSV_OUT}  url,title,email,phone\n
    ${contacts}=    Estrai Contatti Da Pagina  ${URL}
    Table To Pdf  ${CSV_OUT}  ${PDF_OUT}
    Log  ✅ Estrazione completata e salvata in CSV e PDF
    Show Success Notification

*** Keywords ***
Open Browser Headless
    Open Browser    about:blank    browser=chromium    headless=False  # Cambiato a False per debug
    Set Browser Timeout    30 s

Estrai Contatti Da Pagina
    [Arguments]    ${url}
    [Documentation]    Estrae contatti dalla pagina specificata
    TRY
        New Page       ${url}
        ${body}=       Get Text    body
        ${title}=      Get Title
        ${emails}=     Get Regexp Matches    ${body}    [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
        ${phones}=     Get Regexp Matches    ${body}    (?:[+\d]\d[\d\s-]{7,}|\(\d{2,4}\)[\d\s-]+)
        
        ${contacts}=    Create List
        FOR    ${e}    IN    @{emails}
            Append To File    ${CSV_OUT}    "${url}","${title}","${e}",""\n
            Append To List    ${contacts}    ${e}
        END
        FOR    ${p}    IN    @{phones}
            ${clean_phone}=    Clean Phone Number    ${p}
            Append To File    ${CSV_OUT}    "${url}","${title}","","${clean_phone}"\n
            Append To List    ${contacts}    ${clean_phone}
        END
        Close Page
        RETURN    ${contacts}
    EXCEPT    AS    ${error}
        Log    ❌ Errore durante l'estrazione: ${error}    level=ERROR
        RETURN    ${EMPTY}
    END

Clean Phone Number
    [Arguments]    ${phone}
    [Documentation]    Pulisce il numero di telefono rimuovendo spazi e caratteri speciali
    ${clean}=    Replace String    ${phone}    ${SPACE}    ${EMPTY}
    ${clean}=    Replace String    ${clean}    (    ${EMPTY}
    ${clean}=    Replace String    ${clean}    )    ${EMPTY}
    ${clean}=    Replace String    ${clean}    -    ${EMPTY}
    RETURN    ${clean}

Show Success Notification
    Add icon    Success
    Add heading    Estrazione completata con successo
    Add text    I contatti sono stati salvati in:
    Add text    CSV: ${CSV_OUT}
    Add text    PDF: ${PDF_OUT}
    Run dialog    title=Operazione completata