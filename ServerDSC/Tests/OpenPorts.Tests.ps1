param(
  [ValidateNotNullOrEmpty()]
  [string]$IPAddress
)

Describe 'Port 81' {
	$result = Test-NetConnection -Port 81 -ComputerName $IPAddress -InformationLevel "Quiet"
	it 'should should be open' {
		$result | should be $true
	}
}

Describe 'Port 10943' {
	$result = Test-NetConnection -Port 10943 -ComputerName $IPAddress -InformationLevel "Quiet"
	it 'should should be open' {
		$result | should be $true
	}
}