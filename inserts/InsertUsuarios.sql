-- Declaramos las variables necesarias para capturar el código de salida
DECLARE @Resultado INT;

-- Registro 1
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Carlos',
    @inputApellido = 'Martínez',
    @inputPassword = 'password123',
    @inputCorreo = 'carlos.martinez@gmail.com',
    @inputNumTelefono = '5068001234',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 2
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Ana',
    @inputApellido = 'González',
    @inputPassword = 'securepass456',
    @inputCorreo = 'ana.gonzalez@gmail.com',
    @inputNumTelefono = '5068001235',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 3
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'María',
    @inputApellido = 'López',
    @inputPassword = 'mypassword789',
    @inputCorreo = 'maria.lopez@gmail.com',
    @inputNumTelefono = '5068001236',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 4
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Pedro',
    @inputApellido = 'Rodríguez',
    @inputPassword = 'pass1234',
    @inputCorreo = 'pedro.rodriguez@gmail.com',
    @inputNumTelefono = '5068001237',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 5
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Laura',
    @inputApellido = 'Jiménez',
    @inputPassword = 'laurapass567',
    @inputCorreo = 'laura.jimenez@gmail.com',
    @inputNumTelefono = '506123456',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 6
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Gato',
    @inputApellido = 'Villa',
    @inputPassword = 'gato12345',
    @inputCorreo = 'gato.villa@gmail.com',
    @inputNumTelefono = '506945386423',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 7
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Jimena',
    @inputApellido = 'Solis',
    @inputPassword = 'Jimena098',
    @inputCorreo = 'jimena.solis@gmail.com',
    @inputNumTelefono = '5423523563',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 8
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Sarah',
    @inputApellido = 'Navarro',
    @inputPassword = 'passwordsarah',
    @inputCorreo = 'sarah.navarro@gmail.com',
    @inputNumTelefono = '6564365346',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 9
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Pablo',
    @inputApellido = 'Martinez',
    @inputPassword = 'Pablopass234',
    @inputCorreo = 'pablo.martinez@gmail.com',
    @inputNumTelefono = '657456745',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;

-- Registro 10
EXEC [dbo].[Registro_Usuario]
    @inputNombre = 'Paula',
    @inputApellido = 'Mesen',
    @inputPassword = 'PaulaPassword',
    @inputCorreo = 'paula.mesen@gmail.com',
    @inputNumTelefono = '67547878976',
    @inputTipo = 'cliente',
    @outResult = @Resultado OUTPUT;
PRINT @Resultado;
