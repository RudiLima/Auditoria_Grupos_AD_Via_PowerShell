Import-Module ActiveDirectory

# ====== CONFIGURAÇÃO ======
$GrupoNome = "GG_CertA1_MillsTech_0145"
$BaseOU = ""   # opcional - ex: "OU=Usuarios,DC=empresa,DC=local"
$CaminhoSaida = "C:\Temp\RelatorioGrupo"

# ===========================

New-Item -Path $CaminhoSaida -ItemType Directory -Force | Out-Null

Write-Output "Buscando membros do grupo: $GrupoNome"

# Pega membros do grupo (inclui nested)
$membrosGrupo = Get-ADGroupMember -Identity $GrupoNome -Recursive |
Where-Object { $_.objectClass -eq "user" } |
ForEach-Object {
    Get-ADUser $_.DistinguishedName -Properties DisplayName,Mail,Department,Enabled
}

# Exportar membros
$membrosGrupo |
Select-Object DisplayName,SamAccountName,Mail,Department,
@{Name="Status";Expression={ if ($_.Enabled) {"Ativo"} else {"Inativo"} }} |
Export-Csv "$CaminhoSaida\Membros_$GrupoNome.csv" -NoTypeInformation -Delimiter ";" -Encoding UTF8

Write-Output "CSV de membros gerado."

# ==========================================
# AGORA BUSCAR QUEM NÃO ESTÁ NO GRUPO
# ==========================================

Write-Output "Buscando usuários fora do grupo..."

if ($BaseOU -ne "") {
    $todosUsuarios = Get-ADUser -Filter * -SearchBase $BaseOU -Properties DisplayName,Mail,Department,Enabled
}
else {
    $todosUsuarios = Get-ADUser -Filter * -Properties DisplayName,Mail,Department,Enabled
}

$usuariosFora = $todosUsuarios | Where-Object {
    $_.SamAccountName -notin $membrosGrupo.SamAccountName
}

$usuariosFora |
Select-Object DisplayName,SamAccountName,Mail,Department,
@{Name="Status";Expression={ if ($_.Enabled) {"Ativo"} else {"Inativo"} }} |
Export-Csv "$CaminhoSaida\Usuarios_FORA_$GrupoNome.csv" -NoTypeInformation -Delimiter ";" -Encoding UTF8

Write-Output "CSV de usuários fora do grupo gerado."

Write-Output "Processo concluído."