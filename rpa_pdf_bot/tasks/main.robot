*** Settings ***
Library           RPA.Browser.Playwright
Library           RPA.FileSystem
Library           String

Suite Setup       Apri Browser Headless
Suite Teardown    Chiudi Browser

*** Variables ***
${URL_DA_VISITARE}    https://example.com          # ⇦ cambialo con la pagina reale
${OUT_DIR}            ${CURDIR}${/}output
${CSV_FILE}           ${OUT_DIR}${/}contacts.csv

*** Tasks ***
Estrai contatti da pagina singola
    # 1) assicura che la cartella output esista
    Create Directory    ${OUT_DIR}
    # 2) se esiste già il CSV lo rimuovo (evito FileExistsError)
    Run Keyword And Ignore Error    Remove File    ${CSV_FILE}
    # 3) creo il CSV con intestazione
    Create File    ${CSV_FILE}    url,title,email,phone\n
    # 4) faccio lo scraping
    Estrai Contatti Da Pagina    ${URL_DA_VISITARE}
    Log To Console    ✅  Contatti salvati in ${CSV_FILE}

*** Keywords ***
Apri Browser Headless
    New Browser    chromium    headless=True
    New Context

Chiudi Browser
    Close Browser    ALL

Estrai Contatti Da Pagina
    [Arguments]    ${url}
    New Page       ${url}
    Wait For Elements State    body    visible
    ${body}=       Get Text    body
    ${titolo}=     Get Title
    ${emails}=     Get Regexp Matches    ${body}    [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
    ${phones}=     Get Regexp Matches    ${body}    (\+?\d[\d\s().-]{7,})
    Close Page

    # scrivo righe nel CSV
    FOR    ${e}    IN    @{emails}
        Append To File    ${CSV_FILE}    "${url}","${titolo}","${e}",""\n
    END
    FOR    ${p}    IN    @{phones}
        Append To File    ${CSV_FILE}    "${url}","${titolo}","","${p}"\n
    END

