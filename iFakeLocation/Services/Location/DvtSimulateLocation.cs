using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using iMobileDevice;
using iMobileDevice.iDevice;
using iMobileDevice.Lockdown;
using iMobileDevice.Service;

namespace iFakeLocation.Services.Location
{
    internal class DvtSimulateLocation : LocationService
    {
        public DvtSimulateLocation(DeviceInformation device) : base(device) {
        }

        public override void SetLocation(PointLatLng? target) {
            iDeviceHandle deviceHandle = null;
            LockdownClientHandle lockdownHandle = null;
            LockdownServiceDescriptorHandle simulateDescriptor = null;
            ServiceClientHandle serviceClientHandle = null;

            var idevice = LibiMobileDevice.Instance.iDevice;
            var lockdown = LibiMobileDevice.Instance.Lockdown;
            var service = LibiMobileDevice.Instance.Service;

            try {
                // Get device handle
                var err = idevice.idevice_new_with_options(out deviceHandle, _device.UDID, (int) (_device.IsNetwork ? iDeviceOptions.LookupNetwork : iDeviceOptions.LookupUsbmux));
                if (err != iDeviceError.Success)
                    throw new Exception("Unable to connect to the device. Make sure it is connected.");

                // Obtain a lockdown client handle
                if (lockdown.lockdownd_client_new_with_handshake(deviceHandle, out lockdownHandle, "iFakeLocation") !=
                    LockdownError.Success)
                    throw new Exception("Unable to connect to lockdownd.");

                // Start the DVT instruments service for location simulation (iOS 17+)
                // Try multiple service names as Apple may have changed the service name
                string[] dvtServiceNames = {
                    "com.apple.instruments.remoteserver",
                    "com.apple.dt.simulatelocation",  // fallback to DT service
                    "com.apple.instruments.remoteserver.DVTSecureSocketProxy"
                };
                
                bool serviceStarted = false;
                foreach (var serviceName in dvtServiceNames) {
                    if (lockdown.lockdownd_start_service(lockdownHandle, serviceName, out simulateDescriptor) == LockdownError.Success && 
                        !simulateDescriptor.IsInvalid) {
                        serviceStarted = true;
                        break;
                    }
                }
                
                if (!serviceStarted)
                    throw new Exception("Unable to start any DVT service for location simulation on iOS 17+.");

                // Create new service client
                if (service.service_client_new(deviceHandle, simulateDescriptor, out serviceClientHandle) !=
                    ServiceError.Success)
                    throw new Exception("Unable to create DVT service client.");

                if (!target.HasValue) {
                    // Send stop command for DVT
                    SendDvtLocationCommand(serviceClientHandle, null);
                }
                else {
                    // Send start command for DVT
                    SendDvtLocationCommand(serviceClientHandle, target.Value);
                }
            }
            finally {
                if (serviceClientHandle != null)
                    serviceClientHandle.Close();

                if (simulateDescriptor != null)
                    simulateDescriptor.Close();

                if (lockdownHandle != null)
                    lockdownHandle.Close();

                if (deviceHandle != null)
                    deviceHandle.Close();
            }
        }

        private void SendDvtLocationCommand(ServiceClientHandle serviceClientHandle, PointLatLng? location) {
            // For iOS 17+, try to use the same binary protocol as DT service
            // as DVT may be backwards compatible or use a similar protocol
            
            var service = LibiMobileDevice.Instance.Service;
            
            if (!location.HasValue) {
                // Send stop command (same as DT service)
                var stopMessage = ToBytesBE(1); // 0x1 (32-bit big-endian uint)
                uint sent = 0;
                if (service.service_send(serviceClientHandle, stopMessage, (uint)stopMessage.Length, ref sent) !=
                    ServiceError.Success)
                    throw new Exception("Unable to send stop command to DVT service.");
            }
            else {
                // Send start command (same format as DT service)
                var startMessage = ToBytesBE(0); // 0x0 (32-bit big-endian uint)
                var lat = Encoding.ASCII.GetBytes(location.Value.Lat.ToString(CultureInfo.InvariantCulture));
                var lng = Encoding.ASCII.GetBytes(location.Value.Lng.ToString(CultureInfo.InvariantCulture));
                var latLen = ToBytesBE(lat.Length);
                var lngLen = ToBytesBE(lng.Length);
                uint sent = 0;

                // Send the complete message
                var fullMessage = new byte[startMessage.Length + latLen.Length + lat.Length + lngLen.Length + lng.Length];
                var offset = 0;

                Array.Copy(startMessage, 0, fullMessage, offset, startMessage.Length);
                offset += startMessage.Length;

                Array.Copy(latLen, 0, fullMessage, offset, latLen.Length);
                offset += latLen.Length;

                Array.Copy(lat, 0, fullMessage, offset, lat.Length);
                offset += lat.Length;

                Array.Copy(lngLen, 0, fullMessage, offset, lngLen.Length);
                offset += lngLen.Length;

                Array.Copy(lng, 0, fullMessage, offset, lng.Length);

                if (service.service_send(serviceClientHandle, fullMessage, (uint)fullMessage.Length, ref sent) !=
                    ServiceError.Success)
                    throw new Exception("Unable to send location command to DVT service.");
            }
        }

        private static byte[] ToBytesBE(int i) {
            var b = BitConverter.GetBytes((uint)i);
            if (BitConverter.IsLittleEndian) Array.Reverse(b);
            return b;
        }
    }
}
