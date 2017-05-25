using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using Newtonsoft.Json;
using Microsoft.Bot.Builder.Azure;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Builder.Luis;
using Microsoft.Bot.Builder.Luis.Models;
using Microsoft.Bot.Connector;


[Serializable]
public class BasicLuisDialog : LuisDialog<object>
{
    private const string offer1 = "Would you like to schedule an appointment?";
    private const string offer2 = "Would you like to receive a brochure?";

    // Replace this with the Logic App Request URL.
    private static string logicAppURL = "YOUR LOGIC APP URL";
    // Replace this with the URL for the web service
    private static string mlWebServiceURL = "YOUR AML WEB SERVICE URL";
    // Replace this with the API key for the web service
    private static string mlWebServiceApiKey = "YOUR AML WEB SERVICE KEY";

    //TODO use context
    private MsgObj lob = new MsgObj();

    public BasicLuisDialog() : base(new LuisService(new LuisModelAttribute(Utils.GetAppSetting("LuisAppId"), Utils.GetAppSetting("LuisAPIKey"))))
    { }

    [LuisIntent("None")]
    public async Task NoneIntent(IDialogContext context, LuisResult result)
    {
        await interact(context, result, "I didn't understand your request. You can call us at 1-800-FABRIKAM.");
    }

    [LuisIntent("complain about a model")]
    public async Task ComplainIntent(IDialogContext context, LuisResult result)
    {
        await interact(context, result, "We have taken note of your complaint about the {0}.");
    }

    [LuisIntent("get info about a model")]
    public async Task GetInfoIntent(IDialogContext context, LuisResult result)
    {
        await interact(context, result, "You will find detailed information about {0} at http://fabrikam.com/our-range");
    }

    private async Task interact(IDialogContext context, LuisResult result, string message)
    {

        string intent = "false";
        if (result.Intents.Count > 0)
        {
            intent = result.Intents[0].Intent;
        }

        string product = "None";
        foreach (var entity in result.Entities)
        {
            if (entity.Type == "product")
            {
                {
                    product = entity.Entity;
                    break;
                }
            }
        }

        await context.PostAsync(String.Format(message, product));

        lob.Text = result.Query;
        lob.Intent = intent;
        lob.Product = product;
        PostToLogicApp(lob);

        // Randomly select one of the two offers. Replace this with the line
        // below after the ML Web service is trained and deployed
        //string offer = new Random().Next(2) == 0 ? offer1 : offer2;
        string offer = await GetOptimalOfferFromMLService(intent, product);

        lob = lob.Clone();
        lob.Text = offer;

        PromptDialog.Confirm(context, AfterConfirming_interaction, lob.Text, promptStyle: PromptStyle.None);
    }

    public async Task AfterConfirming_interaction(IDialogContext context, IAwaitable<bool> confirmation)
    {
        string message;
        if (await confirmation)
        {
            lob.Intent = "accepted proposal";
            message = $"Ok, done.";
        }
        else
        {
            lob.Intent = "rejected proposal";
            message = $"What else can I help you with?";
        }
        await context.PostAsync(message);

        PostToLogicApp(lob);

        context.Wait(MessageReceived);
    }

    protected override Task<string> GetLuisQueryTextAsync(IDialogContext context, IMessageActivity message)
    {
        lob.ChannelId = message.ChannelId;
        lob.Id = message.Id;
        lob.ServiceUrl = message.ServiceUrl;
        lob.Type = message.Type;
        lob.Timestamp = message.Timestamp;
        lob.UserId = message.From.Id;
        lob.UserName = message.From.Name;
        return base.GetLuisQueryTextAsync(context, message);
    }

    private void PostToLogicApp(MsgObj data)
    {
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(logicAppURL);
        request.ContentType = "application/json";
        request.Method = "POST";

        using (var streamWriter = new StreamWriter(request.GetRequestStream()))
        {
            string json = Newtonsoft.Json.JsonConvert.SerializeObject(data);

            streamWriter.Write(json);
            streamWriter.Flush();
            streamWriter.Close();
        }

        HttpWebResponse response = (HttpWebResponse)request.GetResponse();

        if (response.StatusCode == HttpStatusCode.OK)
        {
            //do something 

        }

    }

    static async Task<String> GetOptimalOfferFromMLService(string intent, string product)
    {
        using (var client = new HttpClient())
        {
            var scoreRequest = new
            {
                Inputs = new Dictionary<string, List<Dictionary<string, string>>>()
                    {
                        {
                            "input1",
                            new List<Dictionary<string, string>>()
                            {
                                new Dictionary<string, string>()
                                {
                                    {"intent", intent},
                                    {"product", product},
                                    {"offer", offer1},
                                    {"outcome", "0"}
                                },
                                new Dictionary<string, string>()
                                {
                                    {"intent", intent},
                                    {"product", product},
                                    {"offer", offer2},
                                    {"outcome", "0"}
                                }
                            }
                        }
                    },
                GlobalParameters = new Dictionary<string, string>() { }
            };

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", mlWebServiceApiKey);
            client.BaseAddress = new Uri(mlWebServiceURL);

            HttpResponseMessage response = await client.PostAsJsonAsync("", scoreRequest);

            if (response.IsSuccessStatusCode)
            {
                var amlWebServiceResponse = await response.Content.ReadAsAsync<AmlResponse>();
                var offer1AcceptProb = amlWebServiceResponse.Results.Outputs[0].Probability;
                var offer2AcceptProb = amlWebServiceResponse.Results.Outputs[1].Probability;
                var offer = offer1AcceptProb >= offer2AcceptProb ? offer1 : offer2;

                System.Diagnostics.Debug.WriteLine("Offer: {0}", offer);
                return offer;
            }
            else
            {
                throw new Exception(string.Format("The request failed with status code: {0} - {1} - {2}", response.StatusCode, response.Headers.ToString(), await response.Content.ReadAsStringAsync()));
            }
        }
    }

}

[Serializable]
public class MsgObj
{
    [JsonProperty("type")]
    public string Type { get; set; }
    [JsonProperty("id")]
    public string Id { get; set; }
    [JsonProperty("timestamp")]
    public DateTime? Timestamp { get; set; }
    [JsonProperty("serviceUrl")]
    public string ServiceUrl { get; set; }
    [JsonProperty("channelId")]
    public string ChannelId { get; set; }
    [JsonProperty("text")]
    public string Text { get; set; }
    [JsonProperty("product")]
    public string Product { get; set; }
    [JsonProperty("intent")]
    public string Intent { get; set; }
    [JsonProperty("userid")]
    public string UserId { get; set; }
    [JsonProperty("username")]
    public string UserName { get; set; }
    public MsgObj Clone() { return (MsgObj)this.MemberwiseClone(); }
}


public class ExecutionOutput
{
    [JsonProperty("intent")]
    public string Intent { get; set; }

    [JsonProperty("product")]
    public string Product { get; set; }

    [JsonProperty("offer")]
    public string Offer { get; set; }

    [JsonProperty("outcome")]
    public string Outcome { get; set; }

    [JsonProperty("Scored Labels")]
    public int Label { get; set; }

    [JsonProperty("Scored Probabilities")]
    public double Probability { get; set; }
}

public class ExecutionResults
{
    [JsonProperty("output1")]
    public List<ExecutionOutput> Outputs { get; set; }
}

public class AmlResponse
{
    public ExecutionResults Results { get; set; }
}


