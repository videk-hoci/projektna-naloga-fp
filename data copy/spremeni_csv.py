import csv

def clear_column(csv_file, column_name, output_file=None):
    """
    Izbriše vse vrednosti v določenem stolpcu CSV datoteke.
    
    Args:
        csv_file: Pot do vhodne CSV datoteke
        column_name: Ime stolpca, ki ga želimo izprazniti
        output_file: Pot do izhodne CSV datoteke (če None, prepiše originalno datoteko)
    
    Primer:
        # Izbriši vrednosti v stolpcu 'hamiltonov' in prepiši originalno datoteko
        clear_column('grafi.csv', 'hamiltonov')
        
        # Izbriši vrednosti v stolpcu 'alpha_od' in shrani v novo datoteko
        clear_column('grafi.csv', 'alpha_od', 'grafi_brez_alpha_od.csv')
    """
    # Če output_file ni podan, uporabi isto datoteko
    if output_file is None:
        output_file = csv_file
    
    # Preberi podatke
    rows = []
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        
        # Preveri, ali stolpec obstaja
        if column_name not in fieldnames:
            print(f"Stolpec '{column_name}' ne obstaja v datoteki.")
            print(f"Obstoječi stolpci: {', '.join(fieldnames)}")
            return
        
        # Preberi vse vrstice in izprazni želeni stolpec
        for row in reader:
            row[column_name] = ''  # Nastavi na prazen string
            rows.append(row)
    
    # Zapiši nazaj v datoteko
    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"✓ Stolpec '{column_name}' izpraznjen v datoteki '{output_file}'")
    print(f"  Število vrstic: {len(rows)}")

def clear_multiple_columns(csv_file, column_names, output_file=None):
    """
    Izbriše vse vrednosti v več stolpcih CSV datoteke.
    
    Args:
        csv_file: Pot do vhodne CSV datoteke
        column_names: Seznam imen stolpcev, ki jih želimo izprazniti
        output_file: Pot do izhodne CSV datoteke (če None, prepiše originalno datoteko)
    
    Primer:
        # Izbriši vrednosti v več stolpcih
        clear_multiple_columns('grafi.csv', ['hamiltonov', 'alpha_od', 'alpha^2'])
    """
    # Če output_file ni podan, uporabi isto datoteko
    if output_file is None:
        output_file = csv_file
    
    # Preberi podatke
    rows = []
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        
        # Preveri, ali vsi stolpci obstajajo
        missing_columns = [col for col in column_names if col not in fieldnames]
        if missing_columns:
            print(f"Naslednji stolpci ne obstajajo: {', '.join(missing_columns)}")
            print(f"Obstoječi stolpci: {', '.join(fieldnames)}")
            return
        
        # Preberi vse vrstice in izprazni želene stolpce
        for row in reader:
            for col in column_names:
                row[col] = ''  # Nastavi na prazen string
            rows.append(row)
    
    # Zapiši nazaj v datoteko
    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"✓ Stolpci izpraznjeni v datoteki '{output_file}':")
    for col in column_names:
        print(f"  - {col}")
    print(f"  Število vrstic: {len(rows)}")

def delete_column(csv_file, column_name, output_file=None):
    """
    Izbriše celoten stolpec iz CSV datoteke (ne samo vrednosti).
    
    Args:
        csv_file: Pot do vhodne CSV datoteke
        column_name: Ime stolpca, ki ga želimo izbrisati
        output_file: Pot do izhodne CSV datoteke (če None, prepiše originalno datoteko)
    
    Primer:
        # Izbriši celoten stolpec 'hamiltonov'
        delete_column('grafi.csv', 'hamiltonov')
    """
    # Če output_file ni podan, uporabi isto datoteko
    if output_file is None:
        output_file = csv_file
    
    # Preberi podatke
    rows = []
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames)
        
        # Preveri, ali stolpec obstaja
        if column_name not in fieldnames:
            print(f"Stolpec '{column_name}' ne obstaja v datoteki.")
            print(f"Obstoječi stolpci: {', '.join(fieldnames)}")
            return
        
        # Odstrani stolpec iz fieldnames
        fieldnames.remove(column_name)
        
        # Preberi vse vrstice brez izbranega stolpca
        for row in reader:
            new_row = {k: v for k, v in row.items() if k != column_name}
            rows.append(new_row)
    
    # Zapiši nazaj v datoteko brez izbranega stolpca
    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"✓ Stolpec '{column_name}' izbrisan iz datoteke '{output_file}'")
    print(f"  Število vrstic: {len(rows)}")
    print(f"  Število preostalih stolpcev: {len(fieldnames)}")


# Primer uporabe:
if __name__ == "__main__":
    # Izbriši vrednosti v stolpcu
    delete_column('data/grafi.csv', 'alpha_od_tilen')
    
    # Izbriši vrednosti v več stolpcih
    # clear_multiple_columns('grafi.csv', ['alpha_od', 'alpha^2'])
    
    # Izbriši celoten stolpec
    # delete_column('grafi.csv', 'hamiltonov')
